import 'package:http/http.dart' as http;

abstract class HttpService {
  Future<http.Response> get(String url, {Map<String, String>? headers});
  Future<http.Response> post(String url, {Map<String, String>? headers, Object? body});
  Future<http.Response> put(String url, {Map<String, String>? headers, Object? body});
  Future<http.StreamedResponse> send(http.BaseRequest request);
}

class RealHttpService implements HttpService {
  final http.Client _client = http.Client();
  static const Duration _timeoutDuration = Duration(seconds: 10);

  @override
  Future<http.Response> get(String url, {Map<String, String>? headers}) {
    return _client
        .get(Uri.parse(url), headers: headers)
        .timeout(_timeoutDuration);
  }

  @override
  Future<http.Response> post(String url, {Map<String, String>? headers, Object? body}) {
    return _client
        .post(Uri.parse(url), headers: headers, body: body)
        .timeout(_timeoutDuration);
  }

  @override
  Future<http.Response> put(String url, {Map<String, String>? headers, Object? body}) {
    return _client
        .put(Uri.parse(url), headers: headers, body: body)
        .timeout(_timeoutDuration);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request);
  }
}
