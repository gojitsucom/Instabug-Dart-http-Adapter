import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:instabug_flutter/instabug_flutter.dart';

import 'instabug_http_log_filter.dart';

class InstabugHttpLogger {
  InstabugHttpLogger({this.logFilter = const _NoOpLogFilter()}) {
    networkLogger = NetworkLogger();
  }

  final InstabugHttpLogFilter logFilter;
  @visibleForTesting
  late NetworkLogger networkLogger;

  void onLogger(http.Response response, {required DateTime startTime}) {
    final http.BaseRequest? request = response.request;

    if (request == null) {
      return;
    }

    final Map<String, dynamic> requestHeaders =
        Map<String, dynamic>.of(request.headers);

    final String requestBody = request is http.MultipartRequest
        ? json.encode(request.fields)
        : request is http.Request
            ? request.body
            : '';

    final Uri requestUri = request.url;
    final NetworkData requestData = NetworkData(
      startTime: startTime,
      method: request.method,
      url: requestUri.toString(),
      requestHeaders:
          logFilter.filterRequestHeaders(requestUri, requestHeaders),
      requestBody: logFilter.filterRequestBody(requestUri, requestBody),
    );

    final DateTime endTime = DateTime.now();

    final Map<String, dynamic> responseHeaders =
        Map<String, dynamic>.of(response.headers);
    int requestBodySize = 0;
    if (requestHeaders.containsKey('content-length')) {
      requestBodySize = int.parse(responseHeaders['content-length'] ?? '0');
    } else {
      requestBodySize = requestBody.length;
    }

    int responseBodySize = 0;
    if (responseHeaders.containsKey('content-length')) {
      responseBodySize = int.parse(responseHeaders['content-length'] ?? '0');
    } else {
      responseBodySize = response.body.length;
    }

    networkLogger.networkLog(requestData.copyWith(
      status: response.statusCode,
      duration: endTime.difference(requestData.startTime).inMicroseconds,
      responseContentType: response.headers.containsKey('content-type')
          ? response.headers['content-type']
          : '',
      responseHeaders:
          logFilter.filterResponseHeaders(requestUri, responseHeaders),
      responseBody: logFilter.filterResponseBody(requestUri, response.body),
      requestBodySize: requestBodySize,
      responseBodySize: responseBodySize,
      requestContentType: request.headers.containsKey('content-type')
          ? request.headers['content-type']
          : '',
    ));
  }
}

class _NoOpLogFilter implements InstabugHttpLogFilter {
  const _NoOpLogFilter();

  @override
  String filterRequestBody(Uri uri, String originalBody) {
    return originalBody;
  }

  @override
  Map<String, dynamic> filterRequestHeaders(
      Uri uri, Map<String, dynamic> originalHeaders) {
    return originalHeaders;
  }

  @override
  String filterResponseBody(Uri uri, String originalBody) {
    return originalBody;
  }

  @override
  Map<String, dynamic> filterResponseHeaders(
      Uri uri, Map<String, dynamic> originalHeaders) {
    return originalHeaders;
  }
}