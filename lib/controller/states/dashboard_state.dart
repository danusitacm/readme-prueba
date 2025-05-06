part of '../bloc/dashboard_bloc.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final List<Post> posts;

  DashboardLoaded({required this.posts});

  @override
  List<Object> get props => [posts];
}

// Nuevo estado para manejar errores
class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});
  
  @override
  List<Object> get props => [message];
}

class PostBodyLoading extends DashboardState {}

class PostBodyLoaded extends DashboardState {
  final Post post;

  PostBodyLoaded({required this.post});

  @override
  List<Object> get props => [post];
}

// Estado para errores en la carga de detalles del post
class PostBodyError extends DashboardState {
  final String message;
  final int postId;
  
  const PostBodyError({required this.message, required this.postId});
  
  @override
  List<Object> get props => [message, postId];
}