import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:luciq_flutter/luciq_flutter.dart';

class LuciqHttpLogger {
  LuciqHttpLogger() : _networkLogger = NetworkLogger();

  final NetworkLogger _networkLogger;

  void onLogger(http.Response response, {DateTime? startTime, W3CHeader? w3CHeader}) {
    final Map<String, dynamic> requestHeaders = <String, dynamic>{};
    response.request?.headers.forEach((String header, dynamic value) {
      requestHeaders[header] = value;
    });

    final http.BaseRequest? request = response.request;

    if (request == null) {
      return;
    }

    // Validate startTime - it should always be provided
    if (startTime == null) {
      throw ArgumentError('startTime is required for network logging');
    }

    final String requestBody = _extractRequestBody(request);

    final NetworkData requestData = NetworkData(
      startTime: startTime,
      method: request.method,
      url: request.url.toString(),
      requestHeaders: requestHeaders,
      requestBody: requestBody,
      w3cHeader: w3CHeader,
    );

    final DateTime endTime = DateTime.now();

    final Map<String, dynamic> responseHeaders = <String, dynamic>{};
    response.headers.forEach((String header, dynamic value) {
      responseHeaders[header] = value;
    });

    final int requestBodySize = _calculateBodySize(
      headers: requestHeaders,
      bodyContent: requestBody,
    );

    final int responseBodySize = _calculateBodySize(
      headers: responseHeaders,
      bodyContent: response.body,
    );

    _networkLogger.networkLog(requestData.copyWith(
      status: response.statusCode,
      duration: endTime.difference(requestData.startTime).inMicroseconds,
      responseContentType: response.headers.containsKey('content-type')
          ? response.headers['content-type']
          : '',
      responseHeaders: responseHeaders,
      responseBody: response.body,
      requestBodySize: requestBodySize,
      responseBodySize: responseBodySize,
      requestContentType: request.headers.containsKey('content-type')
          ? request.headers['content-type']
          : '',
    ));
  }

  String _extractRequestBody(http.BaseRequest request) {
    if (request is http.MultipartRequest) {
      // For multipart requests, include both fields and file information
      final Map<String, dynamic> multipartData = <String, dynamic>{
        'fields': request.fields,
        'files': request.files.map((http.MultipartFile file) => <String, dynamic>{
          'field': file.field,
          'filename': file.filename,
          'contentType': file.contentType.toString(),
          'length': file.length,
        }).toList(),
      };
      return json.encode(multipartData);
    } else if (request is http.Request) {
      return request.body;
    }
    return '';
  }

  int _calculateBodySize({
    required Map<String, dynamic> headers,
    required String bodyContent,
  }) {
    if (headers.containsKey('content-length')) {
      try {
        return int.parse(headers['content-length'].toString());
      } catch (e) {
        // If parsing fails, fall back to body length
        return bodyContent.length;
      }
    }
    return bodyContent.length;
  }
}

// Type alias for backward compatibility
typedef InstabugHttpLogger = LuciqHttpLogger;
