import 'dart:async';
import 'dart:convert';
import 'dart:io';

class FiberhomeClient {
  FiberhomeClient({
    this.host = '192.168.8.1',
    this.username = 'admin',
    required this.password,
    String sessionId = '',
    this.timeout = const Duration(seconds: 10),
  }) : _sessionId = sessionId {
    _http.findProxy = (_) => 'DIRECT';
  }

  final String host;
  final String username;
  final String password;
  final Duration timeout;
  final HttpClient _http = HttpClient();
  String _sessionId;

  String get _normalizedHost {
    return host
        .trim()
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'/$'), '');
  }

  String get sessionId => _sessionId;

  Uri get _toolUri => Uri.parse('http://$_normalizedHost/api/tmp/FHTOOLAPIS');

  Uri get _sessionUri => Uri.parse(
        'http://$_normalizedHost/api/tmp/FHNCAPIS'
        '?ajaxmethod=get_refresh_sessionid',
      );

  Uri _toolGetUri(String ajaxMethod) {
    return Uri.parse('http://$_normalizedHost/api/tmp/FHTOOLAPIS').replace(
      queryParameters: <String, String>{
        'ajaxmethod': ajaxMethod,
        'sessionid': _sessionId.trim(),
      },
    );
  }

  Future<void> login() async {
    if (password.trim().isEmpty && _sessionId.trim().isEmpty) {
      throw StateError('烽火设备需要管理密码，或临时 sessionid。');
    }
    if (_sessionId.trim().isEmpty) {
      _sessionId = await refreshSessionId();
    }
    if (password.trim().isEmpty) {
      return;
    }
    final response = await _post(
      'app_do_login',
      dataObj: <String, String>{
        'username': username.trim().isEmpty ? 'admin' : username.trim(),
        'password': password,
      },
      allowEmptyPassword: true,
    );
    final ret = response['ret'];
    final errmsg = response['errmsg']?.toString() ?? '';
    if (ret != null && ret.toString() != '0' && errmsg.isNotEmpty) {
      throw StateError('烽火登录失败：$errmsg');
    }
    final nextSession = response['sessionid']?.toString() ?? '';
    if (nextSession.isNotEmpty) {
      _sessionId = nextSession;
    }
  }

  Future<String> refreshSessionId() async {
    final request = await _http.getUrl(_sessionUri).timeout(timeout);
    _applyHeaders(request);
    final response = await request.close().timeout(timeout);
    final text = await response.transform(utf8.decoder).join();
    _raiseForStatus(response, text);
    final decoded = _decodeJson(text);
    final nextSession = decoded['sessionid']?.toString() ?? '';
    if (nextSession.isEmpty) {
      throw StateError('烽火 get_refresh_sessionid 未返回 sessionid。');
    }
    return nextSession;
  }

  Future<void> _ensureLoggedIn() async {
    if (_sessionId.trim().isEmpty) {
      await login();
    }
  }

  Future<Map<String, dynamic>> call(
    String ajaxMethod, {
    Object? dataObj,
  }) async {
    await _ensureLoggedIn();
    _sessionId = await refreshSessionId();
    return _post(ajaxMethod, dataObj: dataObj);
  }

  Future<Map<String, dynamic>> _post(
    String ajaxMethod, {
    Object? dataObj,
    bool allowEmptyPassword = false,
  }) async {
    if (_sessionId.trim().isEmpty) {
      throw StateError('烽火设备需要 sessionid。');
    }
    if (!allowEmptyPassword && password.trim().isEmpty) {
      throw StateError('烽火设备需要管理密码。');
    }
    final request = await _http.postUrl(_toolUri).timeout(timeout);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    _applyHeaders(request);
    final payload = encodeToolPayload(
      ajaxMethod: ajaxMethod,
      sessionId: _sessionId.trim(),
      dataObj: dataObj,
    );
    request.contentLength = payload.length;
    request.add(payload);
    final response = await request.close().timeout(timeout);
    final text = await response.transform(utf8.decoder).join();
    _raiseForStatus(response, text);
    return _decodeJson(text);
  }

  Future<Map<String, dynamic>> getTool(String ajaxMethod) async {
    await _ensureLoggedIn();
    final request =
        await _http.getUrl(_toolGetUri(ajaxMethod)).timeout(timeout);
    _applyHeaders(request);
    final response = await request.close().timeout(timeout);
    final text = await response.transform(utf8.decoder).join();
    _raiseForStatus(response, text);
    return _decodeJson(text);
  }

  Future<Map<String, dynamic>> baseInfo() {
    return getTool('app_get_base_info');
  }

  Future<Map<String, dynamic>> airplane() {
    return getTool('app_get_airplane');
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
    await login();
    final nextBaseInfo = await baseInfo();
    return <String, dynamic>{
      'baseInfo': nextBaseInfo,
      'networkInfo': await networkInfo(),
      'lockBand': await lockBand(),
      'cellList': await cellList(),
      'airplane': await airplane(),
      'session': <String, String>{'sessionid': _sessionId},
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

  static List<int> encodeToolPayload({
    required String ajaxMethod,
    required String sessionId,
    Object? dataObj,
  }) {
    return utf8.encode(jsonEncode(<String, Object?>{
      'dataObj': dataObj,
      'ajaxmethod': ajaxMethod,
      'sessionid': sessionId,
    }));
  }

  void _applyHeaders(HttpClientRequest request) {
    request.headers
        .set('Accept', 'application/json, text/javascript, */*; q=0.01');
    request.headers.set('Origin', 'http://$_normalizedHost');
    request.headers.set('Referer', 'http://$_normalizedHost/main.html');
    request.headers.set('User-Agent', 'Mozilla/5.0 CPEManager/0.3.2');
    request.headers.set('X-Requested-With', 'XMLHttpRequest');
    request.headers.set('Accept-Language', 'zh-CN,en,*');
  }

  static Map<String, dynamic> _decodeJson(String text) {
    if (text.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(text);
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{'value': decoded};
  }

  static void _raiseForStatus(HttpClientResponse response, String body) {
    if (response.statusCode >= 400) {
      throw HttpException('HTTP ${response.statusCode}: $body');
    }
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
