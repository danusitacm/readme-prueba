class ApiRoutes {
  /// URL base de la API
  static const String baseUrl = 'http://localhost:8080/api';
  
  // Endpoints de autenticación
  static const String login = '$baseUrl/login';
  static const String logout = '$baseUrl/logout';
  static const String refreshToken = '$baseUrl/token/refresh';
  static const String userAccess = '$baseUrl/token/user-access';
  static const String tokenInfo = '$baseUrl/token/info';
  
  // Endpoints para posts
  static const String posts = '$baseUrl/secure/posts';
  static String getPostById(String postId) => '$posts/$postId';
  
  /// Método para obtener el encabezado de autenticación
  static Map<String, String> getAuthHeader(String token) {
    return {'X-JOKO-AUTH': token};
  }
  
  /// Método para obtener encabezados comunes
  static Map<String, String> getCommonHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers.addAll(getAuthHeader(token));
    }
    
    return headers;
  }
}