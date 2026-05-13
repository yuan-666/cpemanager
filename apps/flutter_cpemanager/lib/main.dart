import 'dart:convert';

import 'package:flutter/material.dart';

import 'api/cpe_client.dart';

void main() {
  runApp(const CpeManagerApp());
}

class CpeManagerApp extends StatelessWidget {
  const CpeManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xff0f766e);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CPE Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xfff8fafc),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xffd7dde5)),
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
    super.dispose();
  }

  CpeClient client() {
    return CpeClient(
      host: hostController.text.trim().isEmpty
          ? '192.168.8.1'
          : hostController.text.trim(),
      username: usernameController.text.trim().isEmpty
          ? 'admin'
          : usernameController.text.trim(),
      password: passwordController.text,
    );
  }

  Future<void> runTask(
      String label, Future<void> Function(CpeClient cpe) task) async {
    if (passwordController.text.isEmpty) {
      setState(() {
        error = '请输入 CPE 管理密码。';
      });
      return;
    }
    setState(() {
      busy = true;
      busyLabel = label;
      error = null;
    });
    try {
      await task(client());
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
    return runTask('读取设备状态', (cpe) async {
      final next = await cpe.snapshot();
      final nextNeighbors = await cpe.neighborCells();
      setState(() {
        snapshot = next;
        neighbors = nextNeighbors;
        rawOutput = const JsonEncoder.withIndent('  ').convert(next);
      });
    });
  }

  Future<void> setAutoMode() async {
    final confirmed = await confirm('恢复自动网络模式并启用 SA+NSA？');
    if (!confirmed) {
      return;
    }
    return runTask('写入网络模式', (cpe) async {
      final result =
          await cpe.setNetMode(networkMode: '00', networkOption: '2');
      final next = await cpe.snapshot();
      setState(() {
        snapshot = next;
        rawOutput = result;
      });
    });
  }

  Future<void> unlockAll() async {
    final confirmed = await confirm('解除所有锁频？这可能改变当前驻网小区。');
    if (!confirmed) {
      return;
    }
    return runTask('解除锁频', (cpe) async {
      final result = await cpe.unlockAll();
      final next = await cpe.snapshot();
      setState(() {
        snapshot = next;
        rawOutput = result;
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
    final signal = mapAt(snapshot, 'signal');
    final traffic = mapAt(snapshot, 'traffic');
    final status = mapAt(snapshot, 'status');
    final plmn = mapAt(snapshot, 'plmn');
    final netMode = mapAt(snapshot, 'netMode');
    final device = mapAt(snapshot, 'device');

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CPE Manager',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xff13211f),
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device['devicename'] ?? 'Huawei CPE mobile console',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: const Color(0xff64748b)),
                    ),
                    const SizedBox(height: 16),
                    ConnectionPanel(
                      hostController: hostController,
                      usernameController: usernameController,
                      passwordController: passwordController,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: busy ? null : refreshSnapshot,
                            child: Text(busy ? busyLabel : '读取状态'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: busy ? null : setAutoMode,
                          child: const Text('自动模式'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: busy ? null : unlockAll,
                          child: const Text('解锁'),
                        ),
                      ],
                    ),
                    if (busy) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(minHeight: 3),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      ErrorPanel(message: error!),
                    ],
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
              sliver: SliverList.list(
                children: [
                  MetricsGrid(
                    signal: signal,
                    traffic: traffic,
                    status: status,
                    plmn: plmn,
                    netMode: netMode,
                  ),
                  const SizedBox(height: 14),
                  NeighborPanel(neighbors: neighbors),
                  const SizedBox(height: 14),
                  RawPanel(rawOutput: rawOutput),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectionPanel extends StatelessWidget {
  const ConnectionPanel({
    required this.hostController,
    required this.usernameController,
    required this.passwordController,
    super.key,
  });

  final TextEditingController hostController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: '连接'),
          const SizedBox(height: 12),
          TextField(
            controller: hostController,
            decoration: const InputDecoration(
                labelText: 'CPE 地址', helperText: '默认 192.168.8.1'),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: '用户名'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '密码'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MetricsGrid extends StatelessWidget {
  const MetricsGrid({
    required this.signal,
    required this.traffic,
    required this.status,
    required this.plmn,
    required this.netMode,
    super.key,
  });

  final Map<String, String> signal;
  final Map<String, String> traffic;
  final Map<String, String> status;
  final Map<String, String> plmn;
  final Map<String, String> netMode;

  @override
  Widget build(BuildContext context) {
    final items = [
      MetricItem('NR RSRP', signal['nrrsrp'] ?? '--'),
      MetricItem('NR SINR', signal['nrsinr'] ?? '--'),
      MetricItem('PCI', signal['pci'] ?? '--'),
      MetricItem('频段', signal['bandInfo'] ?? signal['band'] ?? '--'),
      MetricItem('运营商', plmn['FullName'] ?? plmn['Numeric'] ?? '--'),
      MetricItem('模式', signal['mode'] ?? netMode['NetworkMode'] ?? '--'),
      MetricItem('下载', formatBytes(traffic['CurrentDownload'])),
      MetricItem('WiFi 设备',
          '${status['CurrentWifiUser'] ?? '--'} / ${status['TotalWifiUser'] ?? '--'}'),
    ];

    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: '状态总览'),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 720 ? 4 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  childAspectRatio: columns == 4 ? 2.4 : 2.05,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  return MetricTile(item: items[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class MetricItem {
  const MetricItem(this.label, this.value);

  final String label;
  final String value;
}

class MetricTile extends StatelessWidget {
  const MetricTile({required this.item, super.key});

  final MetricItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: const Color(0xff64748b)),
            ),
            const SizedBox(height: 4),
            Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xff13211f),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class NeighborPanel extends StatelessWidget {
  const NeighborPanel({required this.neighbors, super.key});

  final Map<String, List<Map<String, String>>>? neighbors;

  @override
  Widget build(BuildContext context) {
    final nr = neighbors?['nr'] ?? <Map<String, String>>[];
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'NR 邻区'),
          const SizedBox(height: 8),
          if (nr.isEmpty)
            Text(
              '读取状态后显示按 RSRP 排序的邻区。',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: const Color(0xff64748b)),
            )
          else
            ...nr.take(6).map((cell) => CellRow(cell: cell)),
        ],
      ),
    );
  }
}

class CellRow extends StatelessWidget {
  const CellRow({required this.cell, super.key});

  final Map<String, String> cell;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xffe2e8f0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'PCI ${cell['pci'] ?? '--'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text('B${cell['band'] ?? '--'}'),
          const SizedBox(width: 12),
          Text(cell['rsrp'] ?? '--'),
          const SizedBox(width: 12),
          Text(cell['sinr'] ?? '--'),
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
                  fontFamily: 'monospace', fontSize: 12.5, height: 1.35),
            ),
          ),
        ],
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
        color: const Color(0xfffff1f2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xfffecdd3)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xff9f1239)),
      ),
    );
  }
}

class Surface extends StatelessWidget {
  const Surface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe2e8f0)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 28,
            offset: Offset(0, 18),
            color: Color(0x0f0f172a),
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
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xff13211f),
          ),
    );
  }
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
