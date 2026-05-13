import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_cpemanager/api/fiberhome_client.dart';
import 'package:flutter_cpemanager/main.dart';

void main() {
  test('fiberhome base_info rows are mapped into neighbor cells', () {
    final neighbors = fiberhomeNeighbors(<String, dynamic>{
      'baseInfo': <String, String>{
        'BAND_NBR': 'N78,N79',
        'EARFCN_NBR': '627264,723360',
        'PCI_NBR': '554,891',
        'RSRP_NBR': '-54,-67',
        'RSRQ_NBR': '-9,-11',
        'SINR_NBR': '32,31',
      },
    });

    expect(neighbors['nr'], hasLength(2));
    expect(neighbors['nr']!.first['band'], 'N78');
    expect(neighbors['nr']!.last['pci'], '891');
  });

  test('fiberhome dashboard model renders base_info values', () {
    final model = DashboardModel.from(
      vendor: CpeVendor.fiberhome,
      displayMode: DisplayMode.simple,
      snapshot: <String, dynamic>{
        'baseInfo': <String, String>{
          'modelName': 'LG6151M',
          'WorkMode': 'SA',
          'PLMN': '46000',
          'NR_Band': '79',
          'PCI_NBR': '891',
          'EARFCN_NBR': '723360',
          'DlBandWidth': '100MHz',
          'TAC': '6685291',
          'NCGI': '1657430030',
          'SSB_RSRP': '-67',
          'RSRQ': '-11',
          'SSB_SINR': '31',
          'RSSI': '-57',
          'CQI': '15',
          'Temperature': '36448',
          'RxSpeed': '133911',
          'TxSpeed': '66472',
          'UL_AMBR': '102400',
          'DL_AMBR': '1024000',
          'QCI': '9',
          'DlMCS': '2',
          'UlMCS': '23',
        },
        'networkInfo': <String, String>{'networkMode': '2', 'ENDC': '1'},
        'lockBand': <String, String>{},
        'cellList': <String, Object>{'enable': '0', 'lock_cell': <Object>[]},
      },
      neighbors: <String, List<Map<String, String>>>{
        'nr': <Map<String, String>>[]
      },
    );

    expect(model.headerTitle, '烽火 NR 主小区');
    expect(model.modeBadge, 'SA');
    expect(model.operatorBadge, '中国移动 46000');
    expect(model.primaryItems.first.value, 'N79');
    expect(model.identityItems.any((item) => item.value == '36.4 °C'), isTrue);
    expect(
        model.powerItems.any((item) => item.label.contains('AMBR')), isFalse);
    expect(model.simItems.first.label, '上行签约带宽');
    expect(model.simItems.first.value, '102.4 Mbps');
    expect(model.simItems.last.value, '9');
    expect(model.modulationItems.first.label, '下行调制');
  });

  test('professional mode keeps raw Fiberhome parameter names', () {
    final model = DashboardModel.from(
      vendor: CpeVendor.fiberhome,
      displayMode: DisplayMode.professional,
      snapshot: <String, dynamic>{
        'baseInfo': <String, String>{
          'NR_Band': '79',
          'PCI_NBR': '891',
          'EARFCN_NBR': '723360',
          'DlBandWidth': '100MHz',
          'TAC': '6685291',
          'NCGI': '1657430030',
          'UL_AMBR': '102400',
          'DL_AMBR': '1024000',
          'QCI': '9',
        },
      },
      neighbors: <String, List<Map<String, String>>>{'nr': []},
    );

    expect(model.primaryItems.first.label, 'NR_Band');
    expect(model.simItems.first.label, 'UL_AMBR');
    expect(model.modulationItems.first.label, 'DL_Modulation');
  });

  test('fiberhome JSON POST payload is fixed-length encodable', () {
    final payload = FiberhomeClient.encodeToolPayload(
      ajaxMethod: 'app_get_network_info',
      sessionId: 'sid-for-test',
    );
    final decoded = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;

    expect(decoded['dataObj'], isNull);
    expect(decoded['ajaxmethod'], 'app_get_network_info');
    expect(decoded['sessionid'], 'sid-for-test');
    expect(payload.length, utf8.encode(utf8.decode(payload)).length);
  });

  testWidgets('renders dashboard workspaces and navigation', (tester) async {
    await tester.pumpWidget(const CpeManagerApp());

    expect(find.text('NR 主小区'), findsWidgets);
    expect(find.text('PCC'), findsOneWidget);
    expect(find.text('载波聚合'), findsOneWidget);
    expect(find.text('锁频'), findsOneWidget);
    expect(find.text('速率'), findsOneWidget);
    expect(find.text('设备档案'), findsOneWidget);
    expect(find.text('5秒自动刷新'), findsOneWidget);

    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();

    expect(find.text('连接设备'), findsOneWidget);
    expect(find.text('读取状态'), findsOneWidget);
  });
}
