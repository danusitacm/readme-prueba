import 'package:littlecow/models/token_info_response.dart';
import 'package:littlecow/models/token_response.dart';
import 'package:littlecow/models/user_model.dart';
import 'package:littlecow/services/auth_service.dart';

/// Repositorio que gestiona la autenticación y sesiones de usuario
class AuthRepository {
  final AuthService _authService;
  
  /// Constructor que permite inyección de dependencias para pruebas
  AuthRepository({
    AuthService? authService,
  }) : _authService = authService ?? AuthService();
  
  /// Realiza el inicio de sesión con las credenciales proporcionadas
  Future<JokoTokenResponse> login(String username, String password) async {
    return _authService.login(username, password);
  }
  
  /// Obtiene el usuario actual
  Future<User?> getCurrentUser() async {
    return _authService.getCurrentUser();
  }
  
  /// Cierra la sesión del usuario actual
  Future<void> logout() async {
    await _authService.logout();
  }
  
  /// Verifica si hay una sesión activa y válida
  Future<bool> hasActiveSession() async {
    return _authService.hasValidSession();
  }

  /// Obtiene información del token de acceso actual
  Future<JokoTokenInfoResponse?> getTokenInfo() async {
    return _authService.getTokenInfo();
  }
  
  /// Obtiene un stream que notifica cuando el token se vuelve inválido
  Stream<void> get onTokenInvalid => _authService.onTokenInvalid;
  
  /// Libera recursos cuando ya no se necesita el repositorio
  void dispose() {
    _authService.dispose();
  }
}