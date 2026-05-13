import 'package:flutter_cpemanager/api/cpe_client.dart';
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
}
