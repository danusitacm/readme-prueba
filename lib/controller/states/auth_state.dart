import 'package:equatable/equatable.dart';
import 'package:littlecow/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// Estado inicial, no sabemos si está autenticado o no
class AuthInitial extends AuthState {}

// Estado de carga mientras verificamos autenticación
class AuthLoading extends AuthState {}

// El usuario está autenticado y tiene una sesión válida
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

// El usuario no está autenticado
class AuthUnauthenticated extends AuthState {}

// Error durante la autenticación
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object> get props => [message];
}