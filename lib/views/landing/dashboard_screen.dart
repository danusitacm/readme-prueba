import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../controller/bloc/dashboard_bloc.dart';
import '../../controller/bloc/auth_bloc.dart';
import '../../controller/events/auth_event.dart';
import '../../controller/states/auth_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    developer.log('Building DashboardScreen', name: 'DashboardScreen');
    // Obtenemos el usuario autenticado del estado del AuthBloc
    final authState = context.watch<AuthBloc>().state;
    
    if (authState is AuthAuthenticated) {
      developer.log('User authenticated: ${authState.user.name}', name: 'DashboardScreen');
    } else if (authState is AuthLoading) {
      developer.log('Auth state is loading', name: 'DashboardScreen');
    } else {
      developer.log('User not authenticated or in unknown state: ${authState.runtimeType}', name: 'DashboardScreen');
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // Añadimos botón de notificaciones y logout
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Disparar el evento para cerrar sesión
              context.read<AuthBloc>().add(AuthLoggedOut());
            },
            tooltip: 'Notificaciones',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Disparar el evento para cerrar sesión
              context.read<AuthBloc>().add(AuthLoggedOut());
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            developer.log('Dashboard is loading', name: 'DashboardScreen');
            return const Center(child: CircularProgressIndicator());
          } else if (state is DashboardLoaded) {
            developer.log('Dashboard loaded with ${state.posts.length} posts', name: 'DashboardScreen');
            return ListView.builder(
              itemCount: state.posts.length,
              itemBuilder: (_, index) => ListTile(
                title: Text(state.posts[index].title),
                onTap: () => _showPostBodyModal(context, state.posts[index].id),
              ),
            );
          } else if (state is DashboardError) {
            developer.log('Dashboard error: ${state.message}', name: 'DashboardScreen');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Intentar cargar los datos nuevamente
                      context.read<DashboardBloc>().add(LoadDataEvent());
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          
          // Si no hay datos, cargamos los datos
          if (context.read<DashboardBloc>().state is! DashboardLoaded) {
            developer.log('Dashboard data not loaded, dispatching LoadDataEvent', name: 'DashboardScreen');
            context.read<DashboardBloc>().add(LoadDataEvent());
          }
          
          developer.log('Dashboard data is loading...', name: 'DashboardScreen');
          return const Center(child: Text('Cargando datos...'));
        },
      ),
    );
  }

  void _showPostBodyModal(BuildContext context, int postId) {
    developer.log('Showing post body modal for postId: $postId', name: 'DashboardScreen');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: BlocProvider.of<DashboardBloc>(context),
          child: _PostBodyDialog(postId: postId),
        );
      },
    );
  }
}

class _PostBodyDialog extends StatelessWidget {
  final int postId;

  const _PostBodyDialog({required this.postId});

  @override
  Widget build(BuildContext context) {
    developer.log('Building PostBodyDialog for postId: $postId', name: 'DashboardScreen');
    context.read<DashboardBloc>().add(LoadPostBodyEvent(postId: postId));

    return Dialog(
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is PostBodyLoading) {
            developer.log('Post body is loading for postId: $postId', name: 'DashboardScreen');
            return const Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Cargando contenido..."),
                ],
              ),
            );
          } else if (state is PostBodyLoaded && state.post.id == postId) {
            developer.log('Post body loaded for postId: $postId', name: 'DashboardScreen');
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.post.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(state.post.body),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is PostBodyError && state.postId == postId) {
            developer.log('Error loading post body: ${state.message}', name: 'DashboardScreen');
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cerrar'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<DashboardBloc>().add(LoadPostBodyEvent(postId: postId));
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          
          // Estado por defecto o no reconocido
          developer.log('Unknown post body state: ${state.runtimeType}', name: 'DashboardScreen');
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Error al cargar el post", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
