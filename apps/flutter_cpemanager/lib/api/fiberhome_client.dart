import 'dart:async';
import 'dart:convert';
import 'dart:io';

class FiberhomeClient {
  FiberhomeClient({
    this.host = '192.168.8.1',
    required this.sessionId,
    this.timeout = const Duration(seconds: 10),
  });

  final String host;
  final String sessionId;
  final Duration timeout;
  final HttpClient _http = HttpClient();

  String get _normalizedHost {
    return host
        .trim()
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'/$'), '');
  }

  Uri get _apiUri => Uri.parse('http://$_normalizedHost/api/tmp/FHTOOLAPIS');

  Future<Map<String, dynamic>> call(
    String ajaxMethod, {
    Object? dataObj,
  }) async {
    if (sessionId.trim().isEmpty) {
      throw StateError('烽火设备需要 sessionid。');
    }
    final request = await _http.postUrl(_apiUri).timeout(timeout);
    request.headers.contentType = ContentType.json;
    request.headers.set('Referer', 'http://$_normalizedHost/main.html');
    request.headers.set('User-Agent', 'Mozilla/5.0 CPEManager/0.3.0');
    request.write(jsonEncode(<String, Object?>{
      'dataObj': dataObj,
      'ajaxmethod': ajaxMethod,
      'sessionid': sessionId.trim(),
    }));
    final response = await request.close().timeout(timeout);
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode >= 400) {
      throw HttpException('HTTP ${response.statusCode}: $text');
    }
    if (text.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(text);
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{'value': decoded};
  }

  Future<Map<String, dynamic>> networkInfo() {
    return call('app_get_network_info');
  }

  Future<Map<String, dynamic>> lockBand() {
    return call('app_get_lockband');
  }

  Future<Map<String, dynamic>> cellList() {
    return call('app_get_cell_list');
  }

  Future<Map<String, dynamic>> snapshot() async {
    return <String, dynamic>{
      'networkInfo': await networkInfo(),
      'lockBand': await lockBand(),
      'cellList': await cellList(),
    };
  }

  Future<Map<String, dynamic>> setNetworkMode(FiberhomeNetworkPreset preset) {
    return call(
      'app_set_network_info',
      dataObj: <String, String>{
        'networkMode': preset.networkMode,
        'ENDC': preset.endc,
      },
    );
  }

  Future<Map<String, dynamic>> setLockBand({
    required bool enabled,
    String lteBands = '',
    String nrBands = '',
  }) {
    return call(
      'app_set_lockband',
      dataObj: <String, String>{
        'lockBandEnable': enabled ? '1' : '0',
        'LTELockBAND': lteBands,
        'NRLockBAND': nrBands,
      },
    );
  }

  Future<Map<String, dynamic>> clearLockedCells({bool keepEnabled = true}) {
    return call(
      'app_set_cell_list',
      dataObj: <String, Object>{
        'enable': keepEnabled ? '1' : '0',
        'lock_cell': <Object>[],
      },
    );
  }

  Future<Map<String, dynamic>> setLockedCells({
    required bool enabled,
    required List<FiberhomeLockCell> cells,
  }) {
    return call(
      'app_set_cell_list',
      dataObj: <String, Object>{
        'enable': enabled ? '1' : '0',
        'lock_cell': cells.map((cell) => cell.toJson()).toList(),
      },
    );
  }
}

enum FiberhomeNetworkPreset {
  lteOnly('仅 LTE', '0', '1'),
  saOnly('仅 SA', '2', '1'),
  nsaPreferred('NSA', '3', '2'),
  auto('自动', '3', '3');

  const FiberhomeNetworkPreset(this.label, this.networkMode, this.endc);

  final String label;
  final String networkMode;
  final String endc;
}

class FiberhomeLockCell {
  const FiberhomeLockCell({
    required this.act,
    required this.arfcn,
    required this.pci,
  });

  final String act;
  final String arfcn;
  final String pci;

  Map<String, String> toJson() {
    return <String, String>{
      'act': act,
      'arfcn': arfcn,
      'pci': pci,
    };
  }
}

String fiberhomeNetworkModeText(Map<String, dynamic> networkInfo) {
  final networkMode = networkInfo['networkMode']?.toString();
  final endc = networkInfo['ENDC']?.toString();
  if (networkMode == '0') {
    return 'LTE Only';
  }
  if (networkMode == '2' && endc == '1') {
    return '5G SA';
  }
  if (networkMode == '3' && endc == '2') {
    return '5G NSA';
  }
  if (networkMode == '3' && endc == '3') {
    return 'AUTO';
  }
  return 'M$networkMode / E$endc';
}
