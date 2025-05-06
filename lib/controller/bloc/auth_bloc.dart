import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:littlecow/controller/events/auth_event.dart';
import 'package:littlecow/controller/states/auth_state.dart';
import 'package:littlecow/data/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription? _tokenInvalidSubscription;
  Timer? _tokenVerificationTimer;
  
  AuthBloc({AuthRepository? authRepository}) 
      : _authRepository = authRepository ?? AuthRepository(),
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoggedIn>(_onAuthLoggedIn);
    on<AuthLoggedOut>(_onAuthLoggedOut);
    on<AuthTokenInvalidated>(_onAuthTokenInvalidated);
    // Escucha el evento de token inválido y emite un estado correspondiente
    _tokenInvalidSubscription = _authRepository.onTokenInvalid.listen(
      (_) => add(AuthTokenInvalidated()),
    );
  }

  // Inicia la verificación periódica del token
  void _startTokenVerification() {
    // Cancelar cualquier timer existente antes de crear uno nuevo
    _stopTokenVerification();
    
    // Verificar el token cada 5 minutos
    _tokenVerificationTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      try {
        // Verificar si el token sigue siendo válido
        final tokenInfo = await _authRepository.getTokenInfo();
        if (tokenInfo == null || !tokenInfo.success) {
          // Si el token no es válido, emitir evento de token invalidado
          add(AuthTokenInvalidated());
        }
      } catch (e) {
        print('Error al verificar token: ${e.toString()}');
      }
    });
  }
  
  // Detiene la verificación periódica del token
  void _stopTokenVerification() {
    _tokenVerificationTimer?.cancel();
    _tokenVerificationTimer = null;
  }

  // Maneja el evento de comprobación de autenticación
  FutureOr<void> _onAuthCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Comprueba si hay una sesión válida
      final isAuthenticated = await _authRepository.hasActiveSession();
      
      if (isAuthenticated) {
        // Si hay sesión válida, obtiene el usuario actual
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user));
          
          // Iniciar verificación periódica del token
          _startTokenVerification();
        } else {
          // Si no podemos obtener el usuario, la sesión no es válida
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  // Maneja el evento de inicio de sesión
  FutureOr<void> _onAuthLoggedIn(
      AuthLoggedIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Intenta iniciar sesión
      final loginResponse = await _authRepository.login(
        event.username,
        event.password,
      );
      
      if (loginResponse.success) {
        // Si el login es exitoso, obtiene el usuario actual
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user));
          
          // Iniciar verificación periódica del token
          _startTokenVerification();
        } else {
          emit(const AuthFailure(message: 'No se pudo obtener información del usuario'));
        }
      } else {
        emit(AuthFailure(message: loginResponse.message));
      }
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  // Maneja el evento de cierre de sesión
  FutureOr<void> _onAuthLoggedOut(
      AuthLoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.logout();
      _stopTokenVerification();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }
  
  // Maneja el evento cuando un token se invalida
  FutureOr<void> _onAuthTokenInvalidated(
      AuthTokenInvalidated event, Emitter<AuthState> emit) async {
    emit(const AuthFailure(message: 'La sesión ha expirado. Por favor, inicie sesión nuevamente.'));
    
    await Future.delayed(const Duration(seconds: 2));
    emit(AuthUnauthenticated());
    
    // Limpiamos los tokens almacenados
    await _authRepository.logout();
  }
  
  @override
  Future<void> close() {
    _tokenInvalidSubscription?.cancel();
    _stopTokenVerification();
    _authRepository.dispose();
    return super.close();
  }
}