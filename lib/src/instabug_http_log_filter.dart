abstract class InstabugHttpLogFilter {
  Map<String, dynamic> filterRequestHeaders(
      Uri uri, Map<String, dynamic> originalHeaders) {
    return originalHeaders;
  }

  Map<String, dynamic> filterResponseHeaders(
      Uri uri, Map<String, dynamic> originalHeaders) {
    return originalHeaders;
  }

  String filterRequestBody(Uri uri, String originalBody) {
    return originalBody;
  }

  String filterResponseBody(Uri uri, String originalBody) {
    return originalBody;
  }
}