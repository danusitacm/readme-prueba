import 'package:dio/dio.dart';
import 'dart:async';
import 'package:littlecow/constants/api_routes.dart'; 
import 'package:littlecow/data/secure_storage_service.dart';
import 'package:littlecow/models/token_info_response.dart';
import 'package:littlecow/models/token_response.dart';
import 'package:littlecow/models/user_model.dart';

class AuthService {
  final SecureStorageService _secureStorage;
  final Dio _dio;
  
  // Stream para notificar cuando un token ya no es válido
  final _tokenInvalidController = StreamController<void>.broadcast();
  Stream<void> get onTokenInvalid => _tokenInvalidController.stream;
  
  AuthService({
    SecureStorageService? secureStorage,
    Dio? dio,
  }) : _secureStorage = secureStorage ?? SecureStorageService(),
       _dio = dio ?? Dio();
  
  // Método para iniciar sesión
  Future<JokoTokenResponse> login(String username, String password) async {
    try {
      final response = await _dio.post(
        ApiRoutes.login,
        data: {
          'username': username,
          'password': password,
        },
        options: Options(
          headers: ApiRoutes.getCommonHeaders(),
        ),
      );
      
      final loginResponse = JokoTokenResponse.fromJson(response.data);
      
      // Si la autenticación fue exitosa, guardamos el token y el username
      if (loginResponse.success) {
        await _secureStorage.saveRefreshToken(loginResponse.secret);
        await _secureStorage.saveUsername(username);  // Guardar el username
      }
      return loginResponse;
    } on DioException catch (e) {
      // En caso de error, devolvemos una respuesta con éxito falso
      return JokoTokenResponse(
        secret: '',
        expiration: 0,
        success: false,
        errorCode: 'connection_error',
        message: 'Error de conexión: ${e.message}',
      );
    } catch (e) {
      return JokoTokenResponse(
        secret: '',
        expiration: 0,
        success: false,
        errorCode: 'unexpected_error',
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }
  
  // Método para obtener el token de acceso y la información del usuario
  Future<User?> getAccessTokenAndUser() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      
      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }
      
      // Verificar que las rutas de API estén correctamente configuradas
      print('Intentando obtener access token en: ${ApiRoutes.userAccess}');
      
      final response = await _dio.post(
        ApiRoutes.userAccess,
        options: Options(
          headers: ApiRoutes.getCommonHeaders(token: refreshToken),
          validateStatus: (status) => true, // Aceptar cualquier código de estado para manejar errores manualmente
        ),
      );
      
      // Verificar el código de estado de la respuesta
      if (response.statusCode != 200) {
        print('Error de servidor: Código ${response.statusCode}');
        print('Respuesta del servidor: ${response.data}');
        
        // Si el token ya no es válido, notificar para que se cierre la sesión
        if (response.statusCode == 401) {
          print('Token de acceso inválido o expirado');
          _tokenInvalidController.add(null);
        }
        return null;
      }
      
      final tokenResponse = JokoTokenResponse.fromJson(response.data);
      
      // Verificamos que la respuesta sea exitosa
      if (!tokenResponse.success) {
        print('Error en respuesta del token: ${tokenResponse.message}');
        return null;
      }
      
      // Obtenemos información del usuario usando el token de acceso obtenido
      final accessToken = tokenResponse.secret;
      
      // Guardamos el access token y su tiempo de expiración
      await _secureStorage.saveAccessToken(accessToken);
      
      // Calculamos la fecha de expiración basado en el valor de expiration (segundos)
      // y la guardamos para poder verificar posteriormente si el token ha expirado
      if (tokenResponse.expiration > 0) {
        final expirationDate = DateTime.now().add(Duration(seconds: tokenResponse.expiration));
        await _secureStorage.saveAccessTokenExpiration(expirationDate.millisecondsSinceEpoch);
      }
      
      final tokenInfo = await _getTokenInfoFromToken(accessToken);
      
      if (tokenInfo == null) {
        print('No se pudo obtener información del token');
        return null;
      }
      
      // Creamos un objeto User a partir de la información del token
      final user = User(
        name: tokenInfo.userId, // Valor predeterminado
        // Usar 'audience' como rol en el contexto de la aplicación
        role: tokenInfo.audiencie,
      );
      
      // Guardamos los datos del usuario
      await _secureStorage.saveUserData(user);
      
      return user;
    } on DioException catch (e) {
      print('Error al obtener access token: DioException [${e.type}]: ${e.message}');
      
      // Información detallada para depurar
      if (e.response != null) {
        print('Código de estado: ${e.response?.statusCode}');
        print('Respuesta del servidor: ${e.response?.data}');
      }
      
      // Si es un error de autenticación (401), invalidar el token
      if (e.response?.statusCode == 401) {
        _tokenInvalidController.add(null);
      }
      
      return null;
    } catch (e) {
      print('Error al obtener access token: ${e.toString()}');
      return null;
    }
  }
  
  /// Obtiene información del token de acceso pasado como parámetro
  /// usando el endpoint /api/token/info
  Future<JokoTokenInfoResponse?> _getTokenInfoFromToken(String accessToken) async {
    try {
      if (accessToken.isEmpty) {
        print('Token de acceso vacío');
        return null;
      }
      
      print('Obteniendo información del token en: ${ApiRoutes.tokenInfo}');
      
      // Realizamos la petición al endpoint de información del token
      final response = await _dio.get(
        ApiRoutes.tokenInfo,
        queryParameters: {'accessToken': accessToken},
        options: Options(
          validateStatus: (status) => true, // Aceptar cualquier código para manejar errores manualmente
        ),
      );
      
      // Verificar código de estado
      if (response.statusCode != 200) {
        print('Error al obtener información del token. Código: ${response.statusCode}');
        print('Respuesta del servidor: ${response.data}');
        
        if (response.statusCode == 401) {
          print('Token no autorizado o expirado');
          _tokenInvalidController.add(null);
        }
        return null;
      }
      
      // Convertimos la respuesta en un objeto JokoTokenInfoResponse
      final tokenInfo = JokoTokenInfoResponse.fromJson(response.data);
      
      // Si la respuesta indica un error, notificamos que el token es inválido
      if (!tokenInfo.success) {
        print('Token inválido: ${tokenInfo.message}');
        if (tokenInfo.errorCode.isNotEmpty) {
          print('Código de error: ${tokenInfo.errorCode}');
        }
        _tokenInvalidController.add(null);
        return null;
      }
      
      return tokenInfo;
    } on DioException catch (e) {
      print('Error DioException al obtener información del token: ${e.message}');
      
      // Información detallada para depurar
      if (e.response != null) {
        print('Código de estado: ${e.response?.statusCode}');
        print('Respuesta del servidor: ${e.response?.data}');
      }
      
      // Si es un error de autenticación (401), invalidar el token
      if (e.response?.statusCode == 401) {
        _tokenInvalidController.add(null);
      }
      
      return null;
    } catch (e) {
      print('Error al obtener información del token: ${e.toString()}');
      return null;
    }
  }
  
  // Método para cerrar sesión
  Future<void> logout() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      
      if (refreshToken != null) {
        await _dio.post(
          ApiRoutes.logout,
          options: Options(
            headers: ApiRoutes.getCommonHeaders(token: refreshToken),
          ),
        );
      }
    } catch (e) {
      print('Error al cerrar sesión en servidor: ${e.toString()}');
    } finally {
      //Eliminar los tokens almacenados localmente
      await _secureStorage.deleteAllTokens();
    }
  }
  
  // Método para obtener el usuario actual
  Future<User?> getCurrentUser() async {
    // Primero obtenemos el usuario desde el almacenamiento local
    User? cachedUser = await _secureStorage.getUserData();
    
    // Si tenemos el usuario en cache, lo devolvemos directamente
    if (cachedUser != null) {
      return cachedUser;
    }
    
    // Si no tenemos el usuario en cache, intentamos obtener un nuevo token
    // que también actualizará los datos del usuario
    return await getAccessTokenAndUser();
  }
  
  // Comprobar si tenemos una sesión activa y válida
  Future<bool> hasValidSession() async {
    if (!await _secureStorage.hasRefreshToken()) {
      return false;
    }
    
    // Intentamos obtener un access token para verificar que el refresh token sigue siendo válido
    final user = await getAccessTokenAndUser();
    return user != null;
  }
  
  /// Verifica si el access token actual está expirado
  /// Retorna true si está expirado o no existe, false en caso contrario
  Future<bool> isAccessTokenExpired() async {
    final expirationTimestamp = await _secureStorage.getAccessTokenExpiration();
    
    // Si no hay fecha de expiración guardada, consideramos que el token está expirado
    if (expirationTimestamp == null) {
      return true;
    }
    
    // Verificamos si la fecha actual es posterior a la fecha de expiración
    final expirationDate = DateTime.fromMillisecondsSinceEpoch(expirationTimestamp);
    final now = DateTime.now();
    
    // Añadimos un margen de seguridad (30 segundos) para renovar el token antes de que expire
    return now.isAfter(expirationDate.subtract(const Duration(seconds: 30)));
  }

  /// Obtiene el access token, renovándolo si es necesario
  /// Retorna el token de acceso si es válido o se pudo renovar, null en caso contrario
  Future<String?> getValidAccessToken() async {
    try {
      // Verificamos si hay un access token y si sigue siendo válido
      final accessToken = await _secureStorage.getAccessToken();
      final tokenExpired = await isAccessTokenExpired();
      
      if (accessToken != null && !tokenExpired) {
        return accessToken;
      }
      
      print('Access token expirado o no disponible. Intentando renovar...');
      
      // Si el token ha expirado, intentamos renovarlo usando el refresh token
      final user = await getAccessTokenAndUser();
      if (user != null) {
        final newToken = await _secureStorage.getAccessToken();
        print('Token renovado exitosamente.');
        return newToken;
      }
      
      print('No se pudo renovar el token.');
      // Si no pudimos renovar el token, notificamos que es inválido
      _tokenInvalidController.add(null);
      return null;
    } catch (e) {
      print('Error al obtener un access token válido: ${e.toString()}');
      _tokenInvalidController.add(null);
      return null;
    }
  }
  
  /// Obtiene información del token de acceso actual usando el endpoint /api/token/info
  /// Retorna un objeto JokoTokenInfoResponse con la información del token o null si ocurre un error
  Future<JokoTokenInfoResponse?> getTokenInfo() async {
    try {
      // Obtenemos un access token válido
      final accessToken = await getValidAccessToken();
      
      if (accessToken == null || accessToken.isEmpty) {
        print('No hay token de acceso disponible');
        return null;
      }
      
      return await _getTokenInfoFromToken(accessToken);
    } catch (e) {
      print('Error inesperado al obtener información del token: ${e.toString()}');
      return null;
    }
  }
  
  /// Liberar recursos cuando ya no se necesite el servicio
  void dispose() {
    _tokenInvalidController.close();
  }
}