import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class CpeClient {
  CpeClient({
    this.host = '192.168.8.1',
    this.username = 'admin',
    required this.password,
    this.timeout = const Duration(seconds: 10),
  });

  final String host;
  final String username;
  final String password;
  final Duration timeout;
  final HttpClient _http = HttpClient();
  final Map<String, String> _cookies = <String, String>{};
  String _requestToken = '';

  Uri _uri(String endpoint) {
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return Uri.parse(endpoint);
    }
    return Uri.parse('http://$host$endpoint');
  }

  Future<String> getXml(String endpoint) async {
    final request = await _http.getUrl(_uri(endpoint)).timeout(timeout);
    _applyHeaders(request);
    final response = await request.close().timeout(timeout);
    _captureCookies(response);
    final text = await response.transform(utf8.decoder).join();
    _raiseForStatus(response, text);
    return text;
  }

  Future<String> postXml(String endpoint, String body) async {
    final request = await _http.postUrl(_uri(endpoint)).timeout(timeout);
    _applyHeaders(request);
    request.headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
      charset: 'UTF-8',
    );
    if (_requestToken.isNotEmpty) {
      request.headers.set('__RequestVerificationToken', _requestToken);
    }
    request.write(body);
    final response = await request.close().timeout(timeout);
    _captureCookies(response);
    final text = await response.transform(utf8.decoder).join();
    _raiseForStatus(response, text);
    final token = response.headers.value('__RequestVerificationToken');
    if (token != null && token.isNotEmpty) {
      _requestToken = token;
    }
    return text;
  }

  Future<String> requestToken() async {
    final token = _extractTag(await getXml('/api/webserver/token'), 'token');
    if (token.length > 32) {
      return token.substring(32);
    }
    return token;
  }

  Future<void> login() async {
    await getXml('/');
    await getXml('/api/monitoring/status');
    _requestToken = await requestToken();

    final firstNonce = _randomHex(32);
    final challenge = await postXml(
      '/api/user/challenge_login',
      '<request>'
      '<username>${_xmlEscape(username)}</username>'
      '<firstnonce>$firstNonce</firstnonce>'
      '<mode>1</mode>'
      '<loginflag>2</loginflag>'
      '</request>',
    );
    _raiseForApiCode(challenge, 'challenge_login');
    final salt = _extractTag(challenge, 'salt');
    final iterations = int.parse(_extractTag(challenge, 'iterations'));
    final serverNonce = _extractTag(challenge, 'servernonce');
    if (salt.isEmpty || serverNonce.isEmpty) {
      throw StateError('Login challenge response is missing salt or servernonce.');
    }

    final clientProof = computeClientProof(
      password: password,
      firstNonce: firstNonce,
      saltHex: salt,
      iterations: iterations,
      serverNonce: serverNonce,
    );
    final auth = await postXml(
      '/api/user/authentication_login',
      '<request>'
      '<clientproof>$clientProof</clientproof>'
      '<finalnonce>${_xmlEscape(serverNonce)}</finalnonce>'
      '<loginflag>2</loginflag>'
      '</request>',
    );
    _raiseForApiCode(auth, 'authentication_login');
  }

  Future<Map<String, String>> deviceSignal() async {
    return parseFlat(await getXml('/api/device/signal'));
  }

  Future<Map<String, String>> monitoringStatus() async {
    return parseFlat(await getXml('/api/monitoring/status'));
  }

  Future<Map<String, String>> trafficStatistics() async {
    return parseFlat(await getXml('/api/monitoring/traffic-statistics'));
  }

  Future<Map<String, String>> currentPlmn() async {
    return parseFlat(await getXml('/api/net/current-plmn'));
  }

  Future<Map<String, dynamic>> snapshot() async {
    await login();
    return <String, dynamic>{
      'signal': await deviceSignal(),
      'status': await monitoringStatus(),
      'traffic': await trafficStatistics(),
      'plmn': await currentPlmn(),
    };
  }

  static String computeClientProof({
    required String password,
    required String firstNonce,
    required String saltHex,
    required int iterations,
    required String serverNonce,
  }) {
    final saltedPassword = _pbkdf2HmacSha256(
      utf8.encode(password),
      _hexToBytes(saltHex),
      iterations,
      32,
    );
    final clientKey = Hmac(sha256, utf8.encode('Client Key')).convert(saltedPassword).bytes;
    final storedKey = sha256.convert(clientKey).bytes;
    final signature = Hmac(sha256, storedKey)
        .convert(utf8.encode('$firstNonce,$serverNonce,$serverNonce'))
        .bytes;
    final proof = List<int>.generate(clientKey.length, (index) => clientKey[index] ^ signature[index]);
    return _bytesToHex(proof);
  }

  static List<int> _pbkdf2HmacSha256(
    List<int> passwordBytes,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    if (iterations <= 0) {
      throw ArgumentError.value(iterations, 'iterations', 'must be positive');
    }
    final hmac = Hmac(sha256, passwordBytes);
    final generated = <int>[];
    for (var block = 1; generated.length < keyLength; block += 1) {
      final blockIndex = ByteData(4)..setUint32(0, block, Endian.big);
      var u = hmac.convert(<int>[...salt, ...blockIndex.buffer.asUint8List()]).bytes;
      final t = List<int>.from(u);
      for (var round = 1; round < iterations; round += 1) {
        u = hmac.convert(u).bytes;
        for (var index = 0; index < t.length; index += 1) {
          t[index] ^= u[index];
        }
      }
      generated.addAll(t);
    }
    return generated.take(keyLength).toList();
  }

  static Map<String, String> parseFlat(String xml) {
    final result = <String, String>{};
    final pattern = RegExp(r'<([A-Za-z0-9_]+)>(.*?)</\1>', dotAll: true);
    for (final match in pattern.allMatches(xml)) {
      result[match.group(1)!] = _decodeXml(match.group(2)!.trim());
    }
    return result;
  }

  static String _extractTag(String xml, String tag) {
    final match = RegExp('<$tag>(.*?)</$tag>', dotAll: true).firstMatch(xml);
    return match == null ? '' : _decodeXml(match.group(1)!.trim());
  }

  static List<int> _hexToBytes(String hex) {
    if (hex.length.isOdd) {
      throw FormatException('Invalid hex string length', hex);
    }
    return <int>[
      for (var index = 0; index < hex.length; index += 2)
        int.parse(hex.substring(index, index + 2), radix: 16),
    ];
  }

  static String _bytesToHex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  static String _randomHex(int byteLength) {
    final random = Random.secure();
    return _bytesToHex(List<int>.generate(byteLength, (_) => random.nextInt(256)));
  }

  static String _decodeXml(String value) {
    return value
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&');
  }

  static String _xmlEscape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static void _raiseForApiCode(String xml, String step) {
    final code = _extractTag(xml, 'code');
    if (code.isNotEmpty) {
      throw StateError('$step returned error code $code');
    }
  }

  static void _raiseForStatus(HttpClientResponse response, String body) {
    if (response.statusCode >= 400) {
      throw HttpException('HTTP ${response.statusCode}: $body');
    }
  }

  void _applyHeaders(HttpClientRequest request) {
    request.headers.set('User-Agent', 'CPEManager/0.1.0');
    request.headers.set('X-Requested-With', 'XMLHttpRequest');
    request.headers.set('Cache-Control', 'no-cache');
    request.headers.set('Pragma', 'no-cache');
    if (_cookies.isNotEmpty) {
      request.headers.set(
        HttpHeaders.cookieHeader,
        _cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; '),
      );
    }
  }

  void _captureCookies(HttpClientResponse response) {
    for (final cookie in response.cookies) {
      _cookies[cookie.name] = cookie.value;
    }
  }
}
