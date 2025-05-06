import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// Evento para comprobar el estado actual de la autenticación
class AuthCheckRequested extends AuthEvent {}

// Evento cuando el usuario inicia sesión
class AuthLoggedIn extends AuthEvent {
  final String username;
  final String password;

  const AuthLoggedIn({required this.username, required this.password});

  @override
  List<Object> get props => [username, password];
}

// Evento cuando el usuario cierra sesión
class AuthLoggedOut extends AuthEvent {}

// Evento cuando se detecta que el token ya no es válido
class AuthTokenInvalidated extends AuthEvent {}