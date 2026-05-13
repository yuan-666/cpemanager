import 'package:flutter_cpemanager/api/cpe_client.dart';
import 'package:flutter_cpemanager/api/fiberhome_client.dart';
import 'package:flutter_cpemanager/domain/cell_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseCellList sorts cells by strongest RSRP', () {
    final cells = CpeClient.parseCellList(
      '633984,N78,361,-101dBm,-12dB,-80dBm,3dB;'
      '633984,N78,360,-92dBm,-10dB,-69dBm,17dB',
    );

    expect(cells, hasLength(2));
    expect(cells.first['pci'], '360');
    expect(cells.first['rsrp'], '-92dBm');
  });

  test('cell math converts TAC, ECI, and GCI values', () {
    expect(parseTacDecimal('757E07'), 7699975);
    expect(parseTacDecimal('86fe01'), 8846849);
    expect(computeEci(enbId: '100', cellId: '7'), 25607);
    expect(computeEci(enbId: '411877', cellId: '0'), 105440512);
    expect(computeGci(gnbId: '7706881', cellId: '16'), 31567384592);
    expect(computeGci(gnbId: '234295', cellId: '1040'), 959673360);
    expect(splitGci('1499930752')?.baseId, 366194);
    expect(splitGci('1499930752')?.localCellId, 128);
  });

  test('fiberhome lock cell payload matches captured HAR shape', () {
    expect(
      const FiberhomeLockCell(
        act: '2',
        arfcn: '627264',
        pci: '553',
      ).toJson(),
      <String, String>{
        'act': '2',
        'arfcn': '627264',
        'pci': '553',
      },
    );
  });

  test('fiberhome network mode labels match captured HAR enum pairs', () {
    expect(
      fiberhomeNetworkModeText(<String, dynamic>{
        'networkMode': '0',
        'ENDC': '1',
      }),
      'LTE Only',
    );
    expect(
      fiberhomeNetworkModeText(<String, dynamic>{
        'networkMode': '2',
        'ENDC': '1',
      }),
      '5G SA',
    );
    expect(
      fiberhomeNetworkModeText(<String, dynamic>{
        'networkMode': '3',
        'ENDC': '2',
      }),
      '5G NSA',
    );
    expect(
      fiberhomeNetworkModeText(<String, dynamic>{
        'networkMode': '3',
        'ENDC': '3',
      }),
      'AUTO',
    );
  });
}
