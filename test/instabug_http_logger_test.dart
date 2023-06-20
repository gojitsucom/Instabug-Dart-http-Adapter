import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:instabug_flutter/instabug_flutter.dart';
import 'package:instabug_http_client/src/instabug_http_log_filter.dart';
import 'package:instabug_http_client/src/instabug_http_logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'instabug_http_logger_test.mocks.dart';

@GenerateMocks(<Type>[
  NetworkLogger,
])
void main() {
  group('InstabugHttpLogger', () {
    test('request and response headers can be filtered', () {
      final Map<String, dynamic> originalRequestHeader = <String, dynamic>{
        'Authorization': 'Bearer mySecretToken',
        'SomeOtherHeader': 'Not Sensitive',
      };
      final Map<String, dynamic> originalResponseHeader = <String, dynamic>{
        'SecretToken': 'SomeSensitiveTokenOrSomething',
        'SomeOtherHeader': 'Not Sensitive',
      };
      const String originalRequestBody = 'Original request body';
      const String originalResponseBody = 'Original response body';
      const String modifiedResponseBody = 'modified response body';
      const String modifiedRequestBody = 'modified request body';
      final _SensitiveDataHttpLogFilter filter = _SensitiveDataHttpLogFilter(
        requestHeaderFilter: (Map<String, dynamic> originalHeader) {
          return originalHeader..remove('Authorization');
        },
        requestBodyFilter: (String originalBody) {
          return modifiedRequestBody;
        },
        responseHeaderFilter: (Map<String, dynamic> originalHeader) {
          return originalHeader..remove('SecretToken');
        },
        responseBodyFilter: (String originalBody) {
          return modifiedResponseBody;
        },
      );

      final MockNetworkLogger mockNetworkLogger = MockNetworkLogger();
      when(mockNetworkLogger.networkLog(any))
          .thenAnswer((Invocation realInvocation) async {});
      final InstabugHttpLogger logger = InstabugHttpLogger(
        logFilter: filter,
      )..networkLogger = mockNetworkLogger;
      final Request request = Request('POST', Uri.parse('http://my.api.com'))
        ..headers.addAll(Map<String, String>.from(originalRequestHeader))
        ..body = originalRequestBody;
      final Response response = TestResponse(originalResponseBody, 200,
          request: request,
          headers: Map<String, String>.from(originalResponseHeader));

      // log this fake request
      logger.onLogger(response, startTime: DateTime.now());

      // verify that the logged info excludes filtered items
      final List<dynamic> calls =
          verify(mockNetworkLogger.networkLog(captureAny)).captured;

      expect(calls.length, 1);
      final NetworkData networkData = calls.first;
      expect(networkData.requestHeaders.containsKey('Authorization'), isFalse);
      expect(networkData.responseHeaders.containsKey('SecretToken'), isFalse);
      expect(networkData.requestBody, modifiedRequestBody);
      expect(networkData.responseBody, modifiedResponseBody);
    });
  });
}

typedef TestHeaderFilter = Map<String, dynamic> Function(
    Map<String, dynamic> original);
typedef TestBodyFilter = String Function(String original);

Map<String, dynamic> _defaultHeaderFilter(Map<String, dynamic> original) {
  return original;
}

String _defaultBodyFilter(String original) {
  return original;
}

class _SensitiveDataHttpLogFilter implements InstabugHttpLogFilter {
  _SensitiveDataHttpLogFilter({
    this.requestHeaderFilter = _defaultHeaderFilter,
    this.responseHeaderFilter = _defaultHeaderFilter,
    this.requestBodyFilter = _defaultBodyFilter,
    this.responseBodyFilter = _defaultBodyFilter,
  });

  final TestHeaderFilter requestHeaderFilter;
  final TestHeaderFilter responseHeaderFilter;
  final TestBodyFilter requestBodyFilter;
  final TestBodyFilter responseBodyFilter;

  @override
  String filterRequestBody(Uri uri, String originalBody) {
    return requestBodyFilter(originalBody);
  }

  @override
  Map<String, dynamic> filterRequestHeaders(
      Uri uri, Map<String, dynamic> originalHeaders) {
    return requestHeaderFilter(originalHeaders);
  }

  @override
  String filterResponseBody(Uri uri, String originalBody) {
    return responseBodyFilter(originalBody);
  }

  @override
  Map<String, dynamic> filterResponseHeaders(
      Uri uri, Map<String, dynamic> originalHeaders) {
    return responseHeaderFilter(originalHeaders);
  }
}

class TestResponse extends Response {
  TestResponse(String body, int statusCode,
      {Map<String, String>? headers, BaseRequest? request})
      : _headers = headers ?? const <String, String>{},
        super(
          body,
          statusCode,
          request: request,
        );
  final Map<String, String> _headers;

  @override
  Map<String, String> get headers => _headers;
}
