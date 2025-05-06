import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:littlecow/models/post_model.dart';
import 'package:littlecow/views/security/login_screen.dart';
import 'package:littlecow/views/landing/dashboard_screen.dart'; // Importamos DashboardScreen en vez de HomeScreen
import 'package:littlecow/controller/events/auth_event.dart';
import 'package:littlecow/controller/states/auth_state.dart';

import 'controller/bloc/auth_bloc.dart';
import 'controller/bloc/dashboard_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(AuthCheckRequested()), // Verificar autenticación al iniciar
        ),
        BlocProvider<DashboardBloc>(
          create: (context) => DashboardBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'Little Cow',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            // Mostrar un snackbar cuando hay un error de autenticación
            if (state is AuthFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              // Mostrar una pantalla de carga mientras se verifica la autenticación
              if (state is AuthInitial || state is AuthLoading) {
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              // Si el usuario está autenticado, mostrar el Dashboard
              if (state is AuthAuthenticated) {
                return DashboardScreen();
              }
              
              // Por defecto, mostrar la pantalla de login
              return LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}