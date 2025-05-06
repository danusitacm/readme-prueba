import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:littlecow/models/user_model.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  
  // Claves para los tokens en el almacenamiento seguro
  static const String refreshTokenKey = 'REFRESH_TOKEN';
  static const String accessTokenKey = 'ACCESS_TOKEN';
  static const String accessTokenExpirationKey = 'ACCESS_TOKEN_EXPIRATION';
  static const String userDataKey = 'USER_DATA';
  static const String usernameKey = 'USERNAME'; // Nueva clave para el username
  
  // Constructor del servicio
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();
  
  // Guardar el refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: refreshTokenKey, value: token);
  }
  
  // Obtener el refresh token guardado
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: refreshTokenKey);
  }
  
  // Guardar el access token
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: accessTokenKey, value: token);
  }
  
  // Obtener el access token guardado
  Future<String?> getAccessToken() async {
    return await _storage.read(key: accessTokenKey);
  }
  
  // Guardar la fecha de expiración del access token (en milisegundos desde epoch)
  Future<void> saveAccessTokenExpiration(int expirationTimestamp) async {
    await _storage.write(
        key: accessTokenExpirationKey, value: expirationTimestamp.toString());
  }
  
  // Obtener la fecha de expiración del access token
  Future<int?> getAccessTokenExpiration() async {
    final expirationStr = await _storage.read(key: accessTokenExpirationKey);
    if (expirationStr == null || expirationStr.isEmpty) {
      return null;
    }
    return int.tryParse(expirationStr);
  }
  
  // Eliminar tokens (útil para logout)
  Future<void> deleteAllTokens() async {
    await _storage.delete(key: refreshTokenKey);
    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: accessTokenExpirationKey);
    await deleteUserData(); // También eliminamos los datos del usuario al cerrar sesión
    await deleteUsername(); // Eliminamos el username almacenado
  }
  
  // Verificar si hay un token de actualización guardado
  Future<bool> hasRefreshToken() async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }
  
  // Guardar datos del usuario
  Future<void> saveUserData(User user) async {
    final userJson = jsonEncode(user.toJson());
    await _storage.write(key: userDataKey, value: userJson);
  }
  
  // Obtener datos del usuario guardado
  Future<User?> getUserData() async {
    final userJson = await _storage.read(key: userDataKey);
    if (userJson == null || userJson.isEmpty) {
      return null;
    }
    return User.fromJson(jsonDecode(userJson));
  }
  
  // Eliminar datos del usuario
  Future<void> deleteUserData() async {
    await _storage.delete(key: userDataKey);
  }
  
  // Guardar el username
  Future<void> saveUsername(String username) async {
    await _storage.write(key: usernameKey, value: username);
  }
  
  // Obtener el username guardado
  Future<String?> getUsername() async {
    return await _storage.read(key: usernameKey);
  }
  
  // Eliminar el username (útil para logout)
  Future<void> deleteUsername() async {
    await _storage.delete(key: usernameKey);
  }
}