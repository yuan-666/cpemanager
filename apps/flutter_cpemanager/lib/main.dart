import 'dart:convert';

import 'package:flutter/material.dart';

import 'api/cpe_client.dart';
import 'api/fiberhome_client.dart';
import 'domain/cell_math.dart';

void main() {
  runApp(const CpeManagerApp());
}

enum CpeVendor {
  huawei('Huawei', '华为'),
  fiberhome('Fiberhome', '烽火');

  const CpeVendor(this.code, this.label);

  final String code;
  final String label;
}

class CpeManagerApp extends StatelessWidget {
  const CpeManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = CpeColors.primary;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CPE Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: CpeColors.background,
        useMaterial3: true,
        fontFamilyFallback: const ['PingFang SC', 'Noto Sans CJK SC'],
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: CpeColors.input,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: CpeColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: CpeColors.primary, width: 1.3),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final hostController = TextEditingController(text: '192.168.8.1');
  final usernameController = TextEditingController(text: 'admin');
  final passwordController = TextEditingController();
  final lteBandController = TextEditingController();
  final nrBandController = TextEditingController(text: '41,77,78');
  final lockArfcnController = TextEditingController();
  final lockPciController = TextEditingController();
  final lteLockArfcnController = TextEditingController();
  final lteLockPciController = TextEditingController();

  CpeVendor vendor = CpeVendor.huawei;
  int tabIndex = 1;
  Map<String, dynamic>? snapshot;
  Map<String, List<Map<String, String>>>? neighbors;
  String rawOutput = '';
  String? error;
  bool busy = false;
  String busyLabel = '';

  @override
  void dispose() {
    hostController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    lteBandController.dispose();
    nrBandController.dispose();
    lockArfcnController.dispose();
    lockPciController.dispose();
    lteLockArfcnController.dispose();
    lteLockPciController.dispose();
    super.dispose();
  }

  CpeClient huaweiClient() {
    return CpeClient(
      host: normalizedHost,
      username: usernameController.text.trim().isEmpty
          ? 'admin'
          : usernameController.text.trim(),
      password: passwordController.text,
    );
  }

  FiberhomeClient fiberhomeClient() {
    return FiberhomeClient(
      host: normalizedHost,
      sessionId: passwordController.text,
    );
  }

  String get normalizedHost {
    return hostController.text.trim().isEmpty
        ? '192.168.8.1'
        : hostController.text.trim();
  }

  Future<void> runTask(String label, Future<void> Function() task) async {
    if (passwordController.text.isEmpty) {
      setState(() {
        error = vendor == CpeVendor.huawei
            ? '请输入华为 CPE 管理密码。'
            : '请输入烽火接口 sessionid。';
      });
      return;
    }
    setState(() {
      busy = true;
      busyLabel = label;
      error = null;
    });
    try {
      await task();
    } catch (exception) {
      setState(() {
        error = exception.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          busyLabel = '';
        });
      }
    }
  }

  Future<void> refreshSnapshot() {
    return runTask('读取设备状态', () async {
      if (vendor == CpeVendor.huawei) {
        final cpe = huaweiClient();
        final next = await cpe.snapshot();
        final nextNeighbors = await cpe.neighborCells();
        setState(() {
          snapshot = next;
          neighbors = nextNeighbors;
          rawOutput = const JsonEncoder.withIndent('  ').convert(next);
        });
      } else {
        final cpe = fiberhomeClient();
        final next = await cpe.snapshot();
        setState(() {
          snapshot = next;
          neighbors = fiberhomeNeighbors(next);
          rawOutput = const JsonEncoder.withIndent('  ').convert(next);
        });
      }
    });
  }

  Future<void> setAutoMode() async {
    final confirmed = await confirm(
      vendor == CpeVendor.huawei ? '恢复自动网络模式并启用 SA+NSA？' : '将烽火设备切到 Auto 模式？',
    );
    if (!confirmed) {
      return;
    }
    return runTask('写入网络模式', () async {
      Object result;
      if (vendor == CpeVendor.huawei) {
        result = await huaweiClient().setNetMode(
          networkMode: '00',
          networkOption: '2',
        );
      } else {
        result =
            await fiberhomeClient().setNetworkMode(FiberhomeNetworkPreset.auto);
      }
      await refreshSnapshot();
      setState(() {
        rawOutput = const JsonEncoder.withIndent('  ').convert(result);
      });
    });
  }

  Future<void> unlockAll() async {
    final confirmed = await confirm(
      vendor == CpeVendor.huawei
          ? '解除所有锁频？这可能改变当前驻网小区。'
          : '清空烽火锁小区列表？这会保留锁小区开关状态。',
    );
    if (!confirmed) {
      return;
    }
    return runTask('解除锁定', () async {
      Object result;
      if (vendor == CpeVendor.huawei) {
        result = await huaweiClient().unlockAll();
      } else {
        result = await fiberhomeClient().clearLockedCells();
      }
      await refreshSnapshot();
      setState(() {
        rawOutput = const JsonEncoder.withIndent('  ').convert(result);
      });
    });
  }

  Future<void> setFiberhomeNetwork(FiberhomeNetworkPreset preset) {
    return runTask('写入 ${preset.label}', () async {
      final result = await fiberhomeClient().setNetworkMode(preset);
      await refreshSnapshot();
      setState(() {
        rawOutput = const JsonEncoder.withIndent('  ').convert(result);
      });
    });
  }

  Future<void> setFiberhomeBands() {
    return runTask('写入锁 Band', () async {
      final result = await fiberhomeClient().setLockBand(
        enabled: true,
        lteBands: lteBandController.text.trim(),
        nrBands: nrBandController.text.trim(),
      );
      await refreshSnapshot();
      setState(() {
        rawOutput = const JsonEncoder.withIndent('  ').convert(result);
      });
    });
  }

  Future<void> setFiberhomeCellLock() {
    final arfcn = lockArfcnController.text.trim();
    final pci = lockPciController.text.trim();
    if (arfcn.isEmpty || pci.isEmpty) {
      setState(() {
        error = '请输入 NR ARFCN 和 PCI 后再执行锁小区。';
      });
      return Future<void>.value();
    }
    return runTask('写入锁小区', () async {
      final result = await fiberhomeClient().setLockedCells(
        enabled: true,
        cells: <FiberhomeLockCell>[
          FiberhomeLockCell(
            act: '2',
            arfcn: arfcn,
            pci: pci,
          ),
        ],
      );
      await refreshSnapshot();
      setState(() {
        rawOutput = const JsonEncoder.withIndent('  ').convert(result);
      });
    });
  }

  Future<void> setFiberhomeDualCellLock() {
    final nrArfcn = lockArfcnController.text.trim();
    final nrPci = lockPciController.text.trim();
    final lteArfcn = lteLockArfcnController.text.trim();
    final ltePci = lteLockPciController.text.trim();
    if ([nrArfcn, nrPci, lteArfcn, ltePci].any((value) => value.isEmpty)) {
      setState(() {
        error = '请输入 NR 和 LTE 的 ARFCN/PCI 后再执行 4G+5G 同锁。';
      });
      return Future<void>.value();
    }
    return runTask('写入 4G+5G 同锁', () async {
      final result = await fiberhomeClient().setLockedCells(
        enabled: true,
        cells: <FiberhomeLockCell>[
          FiberhomeLockCell(act: '2', arfcn: nrArfcn, pci: nrPci),
          FiberhomeLockCell(act: '1', arfcn: lteArfcn, pci: ltePci),
        ],
      );
      await refreshSnapshot();
      setState(() {
        rawOutput = const JsonEncoder.withIndent('  ').convert(result);
      });
    });
  }

  Future<bool> confirm(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('确认操作'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('继续'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final model = DashboardModel.from(
      vendor: vendor,
      snapshot: snapshot,
      neighbors: neighbors,
    );
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                child: HeaderPanel(
                  model: model,
                  vendor: vendor,
                  busy: busy,
                  busyLabel: busyLabel,
                  onRefresh: refreshSnapshot,
                  onVendorChanged: (next) {
                    setState(() {
                      vendor = next;
                      snapshot = null;
                      neighbors = null;
                      rawOutput = '';
                      error = null;
                    });
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
              sliver: SliverList.list(
                children: [
                  if (busy) const LinearProgressIndicator(minHeight: 3),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    ErrorPanel(message: error!),
                  ],
                  const SizedBox(height: 12),
                  IndexedStack(
                    index: tabIndex,
                    children: [
                      LoginWorkspace(
                        vendor: vendor,
                        hostController: hostController,
                        usernameController: usernameController,
                        passwordController: passwordController,
                        onRead: busy ? null : refreshSnapshot,
                      ),
                      PccWorkspace(model: model),
                      CarrierWorkspace(model: model),
                      LockWorkspace(
                        vendor: vendor,
                        model: model,
                        lteBandController: lteBandController,
                        nrBandController: nrBandController,
                        lockArfcnController: lockArfcnController,
                        lockPciController: lockPciController,
                        lteLockArfcnController: lteLockArfcnController,
                        lteLockPciController: lteLockPciController,
                        onAuto: busy ? null : setAutoMode,
                        onUnlock: busy ? null : unlockAll,
                        onFiberhomeNetwork: busy ? null : setFiberhomeNetwork,
                        onFiberhomeBands: busy ? null : setFiberhomeBands,
                        onFiberhomeCell: busy ? null : setFiberhomeCellLock,
                        onFiberhomeDualCell:
                            busy ? null : setFiberhomeDualCellLock,
                      ),
                      SpeedWorkspace(model: model, rawOutput: rawOutput),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (index) {
          setState(() {
            tabIndex = index;
          });
        },
        backgroundColor: CpeColors.panel,
        indicatorColor: CpeColors.tileAccent,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: '登录',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune),
            selectedIcon: Icon(Icons.tune),
            label: 'PCC',
          ),
          NavigationDestination(
            icon: Icon(Icons.cell_tower_outlined),
            selectedIcon: Icon(Icons.cell_tower),
            label: '载波聚合',
          ),
          NavigationDestination(
            icon: Icon(Icons.lock_outline),
            selectedIcon: Icon(Icons.lock),
            label: '锁频',
          ),
          NavigationDestination(
            icon: Icon(Icons.speed_outlined),
            selectedIcon: Icon(Icons.speed),
            label: '速率',
          ),
        ],
      ),
    );
  }
}

class HeaderPanel extends StatelessWidget {
  const HeaderPanel({
    required this.model,
    required this.vendor,
    required this.busy,
    required this.busyLabel,
    required this.onRefresh,
    required this.onVendorChanged,
    super.key,
  });

  final DashboardModel model;
  final CpeVendor vendor;
  final bool busy;
  final String busyLabel;
  final VoidCallback onRefresh;
  final ValueChanged<CpeVendor> onVendorChanged;

  @override
  Widget build(BuildContext context) {
    return Surface(
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.headerTitle,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                                color: CpeColors.ink,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      model.subtitle,
                      style: const TextStyle(
                        color: CpeColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: busy ? null : onRefresh,
                icon: const Icon(Icons.refresh),
                label: Text(busy ? busyLabel : '刷新'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedButton<CpeVendor>(
            segments: CpeVendor.values
                .map(
                  (item) => ButtonSegment<CpeVendor>(
                    value: item,
                    label: Text(item.label),
                    icon: Icon(
                      item == CpeVendor.huawei
                          ? Icons.router_outlined
                          : Icons.hub_outlined,
                    ),
                  ),
                )
                .toList(),
            selected: <CpeVendor>{vendor},
            onSelectionChanged: (value) => onVendorChanged(value.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(label: model.modeBadge, strong: true),
              StatusChip(label: model.operatorBadge),
              StatusChip(
                label: model.rrcBadge,
                color: model.rrcBadge.contains('正常')
                    ? CpeColors.good
                    : CpeColors.primary,
              ),
              StatusChip(label: vendor.label),
            ],
          ),
        ],
      ),
    );
  }
}

class LoginWorkspace extends StatelessWidget {
  const LoginWorkspace({
    required this.vendor,
    required this.hostController,
    required this.usernameController,
    required this.passwordController,
    required this.onRead,
    super.key,
  });

  final CpeVendor vendor;
  final TextEditingController hostController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final VoidCallback? onRead;

  @override
  Widget build(BuildContext context) {
    final isHuawei = vendor == CpeVendor.huawei;
    return Column(
      children: [
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: '设备登录'),
              const SizedBox(height: 12),
              FieldBlock(
                label: 'CPE 地址',
                helper: '默认 192.168.8.1',
                child: TextField(
                  controller: hostController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(hintText: '192.168.8.1'),
                ),
              ),
              if (isHuawei) ...[
                const SizedBox(height: 12),
                FieldBlock(
                  label: '用户名',
                  helper: '华为默认 admin',
                  child: TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(hintText: 'admin'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FieldBlock(
                label: isHuawei ? '管理密码' : 'SessionID',
                helper: isHuawei
                    ? '仅本次运行保存在内存中'
                    : '烽火 HAR 只提供 FHTOOLAPIS 调用，当前先使用抓包 sessionid',
                child: TextField(
                  controller: passwordController,
                  obscureText: isHuawei,
                  decoration: InputDecoration(
                    hintText: isHuawei ? 'CPE 管理密码' : '从抓包或登录流程复制',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRead,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('读取状态'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InfoStrip(
          title: isHuawei ? 'Huawei 模式' : 'Fiberhome 模式',
          body: isHuawei
              ? '使用 challenge_login / authentication_login 登录，并读取 signal、PLMN、流量、邻区。'
              : '已从 HAR 接入网络模式、锁 Band、锁小区接口；射频实时状态还需要新的烽火抓包补齐。',
        ),
      ],
    );
  }
}

class PccWorkspace extends StatelessWidget {
  const PccWorkspace({required this.model, super.key});

  final DashboardModel model;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        return Column(
          children: [
            PrimaryCellCard(model: model),
            const SizedBox(height: 12),
            if (compact) ...[
              SignalQualityPanel(model: model),
              const SizedBox(height: 12),
              PowerPanel(model: model),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: SignalQualityPanel(model: model)),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: PowerPanel(model: model)),
                ],
              ),
            const SizedBox(height: 12),
            LinkPanel(model: model),
          ],
        );
      },
    );
  }
}

class CarrierWorkspace extends StatelessWidget {
  const CarrierWorkspace({required this.model, super.key});

  final DashboardModel model;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: '邻区信息'),
              const SizedBox(height: 12),
              CellTable(cells: model.neighborCells),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: '载波聚合'),
              const SizedBox(height: 12),
              EmptyOrText(
                text: model.caSummary,
                empty: '当前没有可展示的辅载波数据。',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LockWorkspace extends StatelessWidget {
  const LockWorkspace({
    required this.vendor,
    required this.model,
    required this.lteBandController,
    required this.nrBandController,
    required this.lockArfcnController,
    required this.lockPciController,
    required this.lteLockArfcnController,
    required this.lteLockPciController,
    required this.onAuto,
    required this.onUnlock,
    required this.onFiberhomeNetwork,
    required this.onFiberhomeBands,
    required this.onFiberhomeCell,
    required this.onFiberhomeDualCell,
    super.key,
  });

  final CpeVendor vendor;
  final DashboardModel model;
  final TextEditingController lteBandController;
  final TextEditingController nrBandController;
  final TextEditingController lockArfcnController;
  final TextEditingController lockPciController;
  final TextEditingController lteLockArfcnController;
  final TextEditingController lteLockPciController;
  final VoidCallback? onAuto;
  final VoidCallback? onUnlock;
  final ValueChanged<FiberhomeNetworkPreset>? onFiberhomeNetwork;
  final VoidCallback? onFiberhomeBands;
  final VoidCallback? onFiberhomeCell;
  final VoidCallback? onFiberhomeDualCell;

  @override
  Widget build(BuildContext context) {
    final isFiberhome = vendor == CpeVendor.fiberhome;
    return Column(
      children: [
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: '配置操作'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionPill(
                    label: '自动模式',
                    icon: Icons.restart_alt,
                    onPressed: onAuto,
                  ),
                  ActionPill(
                    label: isFiberhome ? '清空小区' : '解除锁频',
                    icon: Icons.lock_open,
                    onPressed: onUnlock,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (isFiberhome) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FiberhomeNetworkPreset.values
                      .map(
                        (preset) => ActionPill(
                          label: preset.label,
                          icon: Icons.network_cell,
                          onPressed: onFiberhomeNetwork == null
                              ? null
                              : () => onFiberhomeNetwork!(preset),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FieldBlock(
                        label: 'LTE Band',
                        helper: '例如 1,3,8',
                        child: TextField(controller: lteBandController),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FieldBlock(
                        label: 'NR Band',
                        helper: '例如 41,77,78',
                        child: TextField(controller: nrBandController),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onFiberhomeBands,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('写入锁 Band'),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FieldBlock(
                        label: 'NR ARFCN',
                        helper: 'HAR 示例 627264',
                        child: TextField(controller: lockArfcnController),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FieldBlock(
                        label: 'PCI',
                        helper: 'HAR 示例 553',
                        child: TextField(controller: lockPciController),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FieldBlock(
                        label: 'LTE ARFCN',
                        helper: 'HAR 示例 1000',
                        child: TextField(controller: lteLockArfcnController),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FieldBlock(
                        label: 'LTE PCI',
                        helper: 'HAR 示例 553',
                        child: TextField(controller: lteLockPciController),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onFiberhomeCell,
                        icon: const Icon(Icons.cell_tower),
                        label: const Text('执行 NR 锁小区'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onFiberhomeDualCell,
                        icon: const Icon(Icons.published_with_changes),
                        label: const Text('执行 4G+5G 同锁'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const InfoStrip(
                  title: '烽火写入格式',
                  body:
                      '按 HAR 写入 app_set_cell_list：NR 使用 act=2，LTE 使用 act=1，写完立即读回锁小区列表。',
                ),
              ] else
                EmptyOrText(
                  text: model.lockSummary,
                  empty: 'Huawei 详细锁频表单沿用旧 CLI；移动端本轮先保留自动模式和解除锁频。',
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: '当前锁定状态'),
              const SizedBox(height: 10),
              DenseKvGrid(items: model.lockItems),
            ],
          ),
        ),
      ],
    );
  }
}

class SpeedWorkspace extends StatelessWidget {
  const SpeedWorkspace({
    required this.model,
    required this.rawOutput,
    super.key,
  });

  final DashboardModel model;
  final String rawOutput;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TrafficPanel(model: model),
        const SizedBox(height: 12),
        RawPanel(rawOutput: rawOutput),
      ],
    );
  }
}

class PrimaryCellCard extends StatelessWidget {
  const PrimaryCellCard({required this.model, super.key});

  final DashboardModel model;

  @override
  Widget build(BuildContext context) {
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.headerTitle,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: CpeColors.ink,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      model.subtitle,
                      style: const TextStyle(
                        color: CpeColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(label: model.modeBadge, strong: true),
            ],
          ),
          const SizedBox(height: 14),
          DenseKvGrid(items: model.primaryItems),
          const SizedBox(height: 12),
          DenseKvGrid(items: model.identityItems, compact: true),
        ],
      ),
    );
  }
}

class SignalQualityPanel extends StatelessWidget {
  const SignalQualityPanel({required this.model, super.key});

  final DashboardModel model;

  @override
  Widget build(BuildContext context) {
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: '射频质量'),
          const SizedBox(height: 12),
          for (final item in model.signalBars) ...[
            MetricBar(item: item),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class PowerPanel extends StatelessWidget {
  const PowerPanel({required this.model, super.key});

  final DashboardModel model;

  @override
  Widget build(BuildContext context) {
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: '上行功率'),
          const SizedBox(height: 12),
          for (final item in model.powerItems) ...[
            PowerRow(label: item.label, value: item.value),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class LinkPanel extends StatelessWidget {
  const LinkPanel({required this.model, super.key});

  final DashboardModel model;

  @override
  Widget build(BuildContext context) {
    return Surface(
      tinted: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final downlink = MiniPanel(title: '下行链路', items: model.downlinkItems);
          final uplink = MiniPanel(title: '上行链路', items: model.uplinkItems);
          final download = SpeedTile(label: '下载速率', value: model.downloadRate);
          final upload = SpeedTile(label: '上传速率', value: model.uploadRate);
          return Column(
            children: [
              if (compact) ...[
                downlink,
                const SizedBox(height: 12),
                uplink,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: downlink),
                    const SizedBox(width: 12),
                    Expanded(child: uplink),
                  ],
                ),
              const SizedBox(height: 12),
              if (compact) ...[
                download,
                const SizedBox(height: 12),
                upload,
              ] else
                Row(
                  children: [
                    Expanded(child: download),
                    const SizedBox(width: 12),
                    Expanded(child: upload),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class TrafficPanel extends StatelessWidget {
  const TrafficPanel({required this.model, super.key});

  final DashboardModel model;

  @override
  Widget build(BuildContext context) {
    return Surface(
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: '设备统计'),
          const SizedBox(height: 14),
          DenseKvGrid(items: model.trafficItems),
        ],
      ),
    );
  }
}

class CellTable extends StatelessWidget {
  const CellTable({required this.cells, super.key});

  final List<Map<String, String>> cells;

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) {
      return const EmptyOrText(
        text: '',
        empty: '读取状态后显示邻区或锁小区记录。',
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.0),
          1: FlexColumnWidth(1.4),
          2: FlexColumnWidth(1.0),
          3: FlexColumnWidth(1.1),
          4: FlexColumnWidth(1.1),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: CpeColors.tileAccent),
            children: [
              TableCellText('BAND', head: true),
              TableCellText('ARFCN', head: true),
              TableCellText('PCI', head: true),
              TableCellText('RSRP', head: true),
              TableCellText('RSRQ', head: true),
            ],
          ),
          for (var index = 0; index < cells.take(8).length; index += 1)
            TableRow(
              decoration: BoxDecoration(
                color: index.isEven ? CpeColors.tile : CpeColors.panel,
              ),
              children: [
                TableCellText(
                    cells[index]['band'] ?? cells[index]['act'] ?? '--'),
                TableCellText(
                    cells[index]['earfcn'] ?? cells[index]['arfcn'] ?? '--'),
                TableCellText(cells[index]['pci'] ?? '--'),
                TableCellText(cells[index]['rsrp'] ?? '--'),
                TableCellText(cells[index]['rsrq'] ?? '--'),
              ],
            ),
        ],
      ),
    );
  }
}

class DenseKvGrid extends StatelessWidget {
  const DenseKvGrid({
    required this.items,
    this.compact = false,
    super.key,
  });

  final List<KvItem> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 560 ? 3 : 2;
        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: compact ? 2.45 : 1.75,
          ),
          itemBuilder: (context, index) => KvTile(item: items[index]),
        );
      },
    );
  }
}

class KvTile extends StatelessWidget {
  const KvTile({required this.item, super.key});

  final KvItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.highlight ? CpeColors.tileAccent : CpeColors.tile,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CpeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: CpeColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: CpeColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class MetricBar extends StatelessWidget {
  const MetricBar({required this.item, super.key});

  final BarItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CpeColors.tile,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              item.label,
              style: const TextStyle(
                color: CpeColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: item.progress,
                minHeight: 18,
                backgroundColor: CpeColors.input,
                valueColor: AlwaysStoppedAnimation(item.color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 62,
            child: Text(
              item.value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CpeColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PowerRow extends StatelessWidget {
  const PowerRow({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: CpeColors.tile,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: CpeColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: CpeColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class MiniPanel extends StatelessWidget {
  const MiniPanel({
    required this.title,
    required this.items,
    super.key,
  });

  final String title;
  final List<KvItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CpeColors.tile,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: CpeColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        color: CpeColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    item.value,
                    style: const TextStyle(
                      color: CpeColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class SpeedTile extends StatelessWidget {
  const SpeedTile({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: CpeColors.tile,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: CpeColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: CpeColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class RawPanel extends StatelessWidget {
  const RawPanel({required this.rawOutput, super.key});

  final String rawOutput;

  @override
  Widget build(BuildContext context) {
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: '原始快照'),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 120),
            child: SelectableText(
              rawOutput.isEmpty ? '暂无数据。' : rawOutput,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FieldBlock extends StatelessWidget {
  const FieldBlock({
    required this.label,
    required this.helper,
    required this.child,
    super.key,
  });

  final String label;
  final String helper;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: CpeColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        child,
        const SizedBox(height: 4),
        Text(
          helper,
          style: const TextStyle(color: CpeColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    this.strong = false,
    this.color,
    super.key,
  });

  final String label;
  final bool strong;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.14) ??
            (strong ? CpeColors.tileAccent : CpeColors.tile),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color ?? CpeColors.ink,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class ActionPill extends StatelessWidget {
  const ActionPill({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class InfoStrip extends StatelessWidget {
  const InfoStrip({
    required this.title,
    required this.body,
    super.key,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CpeColors.notice,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CpeColors.noticeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: CpeColors.noticeText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(color: CpeColors.noticeText),
          ),
        ],
      ),
    );
  }
}

class EmptyOrText extends StatelessWidget {
  const EmptyOrText({
    required this.text,
    required this.empty,
    super.key,
  });

  final String text;
  final String empty;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.trim().isEmpty ? empty : text,
      style: const TextStyle(
        color: CpeColors.muted,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
    );
  }
}

class TableCellText extends StatelessWidget {
  const TableCellText(this.text, {this.head = false, super.key});

  final String text;
  final bool head;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: CpeColors.ink,
          fontWeight: head ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
    );
  }
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CpeColors.error,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CpeColors.errorBorder),
      ),
      child: Text(
        message,
        style: const TextStyle(color: CpeColors.errorText),
      ),
    );
  }
}

class Surface extends StatelessWidget {
  const Surface({
    required this.child,
    this.tinted = false,
    super.key,
  });

  final Widget child;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tinted ? CpeColors.panel : CpeColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CpeColors.border),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 12),
            color: CpeColors.shadow,
          ),
        ],
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: CpeColors.primary,
            letterSpacing: 0,
          ),
    );
  }
}

class DashboardModel {
  const DashboardModel({
    required this.vendor,
    required this.headerTitle,
    required this.subtitle,
    required this.modeBadge,
    required this.operatorBadge,
    required this.rrcBadge,
    required this.primaryItems,
    required this.identityItems,
    required this.signalBars,
    required this.powerItems,
    required this.downlinkItems,
    required this.uplinkItems,
    required this.trafficItems,
    required this.neighborCells,
    required this.caSummary,
    required this.lockSummary,
    required this.lockItems,
    required this.downloadRate,
    required this.uploadRate,
  });

  final CpeVendor vendor;
  final String headerTitle;
  final String subtitle;
  final String modeBadge;
  final String operatorBadge;
  final String rrcBadge;
  final List<KvItem> primaryItems;
  final List<KvItem> identityItems;
  final List<BarItem> signalBars;
  final List<KvItem> powerItems;
  final List<KvItem> downlinkItems;
  final List<KvItem> uplinkItems;
  final List<KvItem> trafficItems;
  final List<Map<String, String>> neighborCells;
  final String caSummary;
  final String lockSummary;
  final List<KvItem> lockItems;
  final String downloadRate;
  final String uploadRate;

  factory DashboardModel.from({
    required CpeVendor vendor,
    required Map<String, dynamic>? snapshot,
    required Map<String, List<Map<String, String>>>? neighbors,
  }) {
    if (vendor == CpeVendor.fiberhome) {
      return DashboardModel._fiberhome(snapshot, neighbors);
    }
    return DashboardModel._huawei(snapshot, neighbors);
  }

  factory DashboardModel._huawei(
    Map<String, dynamic>? snapshot,
    Map<String, List<Map<String, String>>>? neighbors,
  ) {
    final signal = mapAt(snapshot, 'signal');
    final traffic = mapAt(snapshot, 'traffic');
    final status = mapAt(snapshot, 'status');
    final plmn = mapAt(snapshot, 'plmn');
    final netMode = mapAt(snapshot, 'netMode');
    final mode = firstValue(signal, ['mode'], fallback: '--');
    final nrMode = mode == '12' ? '5G SA/NR' : (mode == '7' ? 'LTE' : 'NR/LTE');
    final tacDecimal = decimalText(parseTacDecimal(signal['tac']));
    final gci = firstValue(signal, ['cell_id', 'gci', 'nr_cell_id']);
    final gnbId = firstValue(
      signal,
      ['gnb_id', 'nr_gNB_ID', 'enodeb_id'],
      fallback: '',
    );
    final nrLocalCellId = firstValue(
      signal,
      ['nr_cell_id_4bit', 'local_cell_id', 'cellid'],
      fallback: '',
    );
    final computedGci = computeGci(gnbId: gnbId, cellId: nrLocalCellId);
    final displayedGci = computedGci ?? parseFlexibleInt(gci);
    final gnbCell = deriveNrGnbCell(
      gnbId: gnbId,
      localCellId: nrLocalCellId,
      gci: gci,
    );
    final eci = computeEci(
      enbId: signal['enodeb_id'],
      cellId: firstValue(signal, ['lte_cell_id', 'cellid'], fallback: ''),
    );
    return DashboardModel(
      vendor: CpeVendor.huawei,
      headerTitle: mode == '7' ? 'LTE 主小区' : 'NR 主小区',
      subtitle: nrMode,
      modeBadge: mode == '12' ? '5G SA' : (netMode['NetworkMode'] ?? nrMode),
      operatorBadge: operatorLabel(plmn),
      rrcBadge: signal['rrc_status'] == '1'
          ? 'RRC 正常'
          : 'RRC ${signal['rrc_status'] ?? '--'}',
      primaryItems: [
        KvItem('Band', cleanBand(firstValue(signal, ['bandInfo', 'band']))),
        KvItem('PCI', firstValue(signal, ['pci'])),
        KvItem('SS-ARFCN', firstValue(signal, ['nrearfcn', 'earfcn'])),
        KvItem('BW', firstValue(signal, ['nrdlbandwidth', 'bandwidth'])),
        KvItem('TAC 十进制', tacDecimal),
        KvItem('GCI 十进制', decimalText(displayedGci)),
      ],
      identityItems: [
        KvItem('gNB - Cell', gnbCell),
        KvItem('NR CellID', decimalText(parseFlexibleInt(gci))),
        KvItem('TAC 原始', firstValue(signal, ['tac'])),
        KvItem('DL / UL', dlUlText(signal)),
        KvItem('ECI(LTE)', decimalText(eci)),
      ],
      signalBars: [
        BarItem.rsrp(firstValue(signal, ['nrrsrp', 'rsrp'])),
        BarItem.rsrq(firstValue(signal, ['nrrsrq', 'rsrq'])),
        BarItem.sinr(firstValue(signal, ['nrsinr', 'sinr'])),
        BarItem.rssi(firstValue(signal, ['nrrssi', 'rssi'])),
        BarItem.cqi(firstValue(signal, ['nrcqi0', 'cqi'])),
      ],
      powerItems: parsePower(firstValue(signal, ['nrtxpower'])),
      downlinkItems: [
        KvItem('MCS', parseMcs(firstValue(signal, ['nrdlmcs']))),
        KvItem('调制', parseModulation(firstValue(signal, ['nrdlmcs']))),
        KvItem('RANK', firstValue(signal, ['nrrank'])),
      ],
      uplinkItems: [
        KvItem('MCS', parseMcs(firstValue(signal, ['nrulmcs']))),
        KvItem('调制', parseModulation(firstValue(signal, ['nrulmcs']))),
        const KvItem('MIMO', '--'),
      ],
      trafficItems: [
        KvItem('当前下载', formatBytes(firstValue(traffic, ['CurrentDownload']))),
        KvItem('当前上传', formatBytes(firstValue(traffic, ['CurrentUpload']))),
        KvItem(
            '当前总量', formatBytes(firstValue(traffic, ['CurrentConnectTime']))),
        KvItem('总下载', formatBytes(firstValue(traffic, ['TotalDownload']))),
        KvItem('总上传', formatBytes(firstValue(traffic, ['TotalUpload']))),
        KvItem('WiFi 设备',
            '${status['CurrentWifiUser'] ?? '--'} / ${status['TotalWifiUser'] ?? '--'}'),
      ],
      neighborCells: neighbors?['nr'] ?? <Map<String, String>>[],
      caSummary: 'NR 辅小区接口已预留；当前主界面优先展示邻区和 PCC。',
      lockSummary:
          'NetworkMode=${netMode['NetworkMode'] ?? '--'}  LTEBand=${netMode['LTEBand'] ?? '--'}',
      lockItems: [
        KvItem('NetworkMode', netMode['NetworkMode'] ?? '--'),
        KvItem('networkOption', netMode['networkOption'] ?? '--'),
        KvItem('LTEBand', netMode['LTEBand'] ?? '--'),
        KvItem('NetworkBand', netMode['NetworkBand'] ?? '--'),
      ],
      downloadRate: rateText(traffic['CurrentDownloadRate']),
      uploadRate: rateText(traffic['CurrentUploadRate']),
    );
  }

  factory DashboardModel._fiberhome(
    Map<String, dynamic>? snapshot,
    Map<String, List<Map<String, String>>>? neighbors,
  ) {
    final network = mapAt(snapshot, 'networkInfo');
    final lockBand = mapAt(snapshot, 'lockBand');
    final cellList = mapAt(snapshot, 'cellList');
    final mode = fiberhomeNetworkModeText(network);
    final enabled = cellList['enable'] == '1' ? '开启' : '关闭';
    return DashboardModel(
      vendor: CpeVendor.fiberhome,
      headerTitle: '烽火配置面板',
      subtitle: 'FHTOOLAPIS / 配置操作',
      modeBadge: mode,
      operatorBadge: 'Fiberhome',
      rrcBadge: '配置接口',
      primaryItems: [
        KvItem('网络模式', network['networkMode'] ?? '--'),
        KvItem('ENDC', network['ENDC'] ?? '--'),
        KvItem('锁 Band', lockBand['lockBandEnable'] == '1' ? '开启' : '关闭'),
        KvItem('锁小区', enabled),
        KvItem('NR Band', lockBand['NRLockBAND'] ?? '--'),
        KvItem('LTE Band', lockBand['LTELockBAND'] ?? '--'),
      ],
      identityItems: [
        const KvItem('接口', 'FHTOOLAPIS'),
        const KvItem('TAC 十进制', '--'),
        const KvItem('GCI 十进制', '--'),
        const KvItem('ECI(LTE)', '--'),
        KvItem('锁定记录', '${neighbors?['nr']?.length ?? 0} 条'),
        const KvItem('Session', '手动'),
      ],
      signalBars: [
        BarItem.placeholder('RSRP'),
        BarItem.placeholder('RSRQ'),
        BarItem.placeholder('SINR'),
        BarItem.placeholder('RSSI'),
        BarItem.placeholder('CQI'),
      ],
      powerItems: const [
        KvItem('PUSCH', '--'),
        KvItem('PUCCH', '--'),
        KvItem('SRS', '--'),
        KvItem('PRACH', '--'),
      ],
      downlinkItems: const [
        KvItem('MCS', '--'),
        KvItem('调制', '--'),
        KvItem('RANK', '--'),
      ],
      uplinkItems: const [
        KvItem('MCS', '--'),
        KvItem('调制', '--'),
        KvItem('MIMO', '--'),
      ],
      trafficItems: const [
        KvItem('下载速率', '--'),
        KvItem('上传速率', '--'),
        KvItem('设备温度', '--'),
        KvItem('软件版本', '--'),
        KvItem('当月下载', '--'),
        KvItem('当月上传', '--'),
      ],
      neighborCells: neighbors?['nr'] ?? <Map<String, String>>[],
      caSummary: 'HAR 目前只包含配置接口；连接/邻区/设备统计需要继续补抓。',
      lockSummary:
          'NR=${lockBand['NRLockBAND'] ?? '--'} LTE=${lockBand['LTELockBAND'] ?? '--'}',
      lockItems: [
        KvItem('lockBandEnable', lockBand['lockBandEnable'] ?? '--'),
        KvItem('NRLockBAND', lockBand['NRLockBAND'] ?? '--'),
        KvItem('LTELockBAND', lockBand['LTELockBAND'] ?? '--'),
        KvItem('cellLock', enabled),
      ],
      downloadRate: '--',
      uploadRate: '--',
    );
  }
}

class KvItem {
  const KvItem(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;
}

class BarItem {
  const BarItem({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  factory BarItem.rsrp(String value) {
    final number = numeric(value);
    return BarItem(
      label: 'RSRP',
      value: value,
      progress: normalize(number, -120, -70),
      color: number != null && number > -95 ? CpeColors.good : CpeColors.warn,
    );
  }

  factory BarItem.rsrq(String value) {
    final number = numeric(value);
    return BarItem(
      label: 'RSRQ',
      value: value,
      progress: normalize(number, -20, -6),
      color: number != null && number > -12 ? CpeColors.good : CpeColors.warn,
    );
  }

  factory BarItem.sinr(String value) {
    final number = numeric(value);
    return BarItem(
      label: 'SINR',
      value: value,
      progress: normalize(number, 0, 30),
      color: number != null && number > 12 ? CpeColors.good : CpeColors.warn,
    );
  }

  factory BarItem.rssi(String value) {
    final number = numeric(value);
    return BarItem(
      label: 'RSSI',
      value: value,
      progress: normalize(number, -100, -45),
      color: CpeColors.good,
    );
  }

  factory BarItem.cqi(String value) {
    final number = numeric(value);
    return BarItem(
      label: 'CQI0',
      value: value,
      progress: normalize(number, 0, 15),
      color: CpeColors.good,
    );
  }

  factory BarItem.placeholder(String label) {
    return BarItem(
      label: label,
      value: '--',
      progress: 0,
      color: CpeColors.primary,
    );
  }

  final String label;
  final String value;
  final double progress;
  final Color color;
}

class CpeColors {
  static const background = Color(0xff0f1217);
  static const surface = Color(0xff171c23);
  static const panel = Color(0xff121821);
  static const input = Color(0xff202733);
  static const tile = Color(0xff1d2430);
  static const tileAccent = Color(0xff26364a);
  static const border = Color(0xff303846);
  static const primary = Color(0xff8fb3ff);
  static const ink = Color(0xfff5f7fb);
  static const muted = Color(0xff9ba7b8);
  static const good = Color(0xff49d184);
  static const warn = Color(0xffffc857);
  static const notice = Color(0xff2b2414);
  static const noticeBorder = Color(0xff77622a);
  static const noticeText = Color(0xffffd66b);
  static const error = Color(0xff33171d);
  static const errorBorder = Color(0xff7f2a3a);
  static const errorText = Color(0xffff9bad);
  static const shadow = Color(0x66000000);
}

Map<String, String> mapAt(Map<String, dynamic>? value, String key) {
  final item = value?[key];
  if (item is Map<String, String>) {
    return item;
  }
  if (item is Map) {
    return item.map((key, value) => MapEntry(key.toString(), value.toString()));
  }
  return <String, String>{};
}

Map<String, List<Map<String, String>>> fiberhomeNeighbors(
  Map<String, dynamic> snapshot,
) {
  final cellList = snapshot['cellList'];
  if (cellList is! Map) {
    return <String, List<Map<String, String>>>{'nr': []};
  }
  final records = cellList['lock_cell'];
  if (records is! List) {
    return <String, List<Map<String, String>>>{'nr': []};
  }
  return <String, List<Map<String, String>>>{
    'nr': records.whereType<Map>().map((item) {
      return <String, String>{
        'band': item['act'] == '2' ? 'NR' : 'LTE',
        'act': item['act']?.toString() ?? '--',
        'arfcn': item['arfcn']?.toString() ?? '--',
        'pci': item['pci']?.toString() ?? '--',
        'rsrp': '--',
        'rsrq': '--',
      };
    }).toList(),
  };
}

String firstValue(
  Map<String, String> data,
  List<String> keys, {
  String fallback = '--',
}) {
  for (final key in keys) {
    final value = data[key];
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return fallback;
}

String operatorLabel(Map<String, String> plmn) {
  final full = plmn['FullName'] ?? plmn['fullname'] ?? '';
  final numeric = plmn['Numeric'] ?? plmn['numeric'] ?? plmn['plmn'] ?? '';
  if (full.isNotEmpty && numeric.isNotEmpty) {
    return '$full $numeric';
  }
  if (full.isNotEmpty) {
    return full;
  }
  if (numeric.isNotEmpty) {
    return numeric;
  }
  return '--';
}

String cleanBand(String value) {
  if (value == '--') {
    return value;
  }
  final match = RegExp(r'\((N?\d+)\)').firstMatch(value);
  if (match != null) {
    return match.group(1)!;
  }
  return value.replaceAll('MHz@', 'M@');
}

String dlUlText(Map<String, String> signal) {
  final dl = firstValue(signal, ['nrdlfreq', 'ltedlfreq']);
  final ul = firstValue(signal, ['nrulfreq', 'lteulfreq']);
  if (dl == '--' && ul == '--') {
    return '--';
  }
  return '${formatKhz(dl)} / ${formatKhz(ul)}';
}

String formatKhz(String value) {
  final number = numeric(value);
  if (number == null) {
    return value;
  }
  if (value.toLowerCase().contains('khz')) {
    return '${(number / 1000).toStringAsFixed(2)} MHz';
  }
  return value;
}

List<KvItem> parsePower(String value) {
  if (value == '--') {
    return const [
      KvItem('PUSCH', '--'),
      KvItem('PUCCH', '--'),
      KvItem('SRS', '--'),
      KvItem('PRACH', '--'),
    ];
  }
  final labels = <String, String>{
    'PPusch': 'PUSCH',
    'PPucch': 'PUCCH',
    'PSrs': 'SRS',
    'PPrach': 'PRACH',
  };
  final items = <KvItem>[];
  for (final entry in labels.entries) {
    final match = RegExp('${entry.key}:([^\\s]+)').firstMatch(value);
    items.add(KvItem(entry.value, match?.group(1) ?? '--'));
  }
  return items;
}

String parseMcs(String value) {
  final match = RegExp(r':(\d+)@').firstMatch(value);
  return match?.group(1) ?? '--';
}

String parseModulation(String value) {
  final match = RegExp(r'@([A-Za-z0-9]+)').firstMatch(value);
  return match?.group(1) ?? '--';
}

String formatBytes(String? value) {
  final bytes = int.tryParse(value ?? '');
  if (bytes == null) {
    return '--';
  }
  if (bytes >= 1073741824) {
    return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
  }
  if (bytes >= 1048576) {
    return '${(bytes / 1048576).toStringAsFixed(2)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(2)} KB';
  }
  return '$bytes B';
}

String rateText(String? value) {
  final bytes = int.tryParse(value ?? '');
  if (bytes == null) {
    return '--';
  }
  return '${(bytes * 8 / 1000000).toStringAsFixed(2)} Mbps';
}

double? numeric(String value) {
  return double.tryParse(value.replaceAll(RegExp(r'[^0-9.\-]'), ''));
}

double normalize(double? value, double min, double max) {
  if (value == null) {
    return 0;
  }
  return ((value - min) / (max - min)).clamp(0.0, 1.0);
}
