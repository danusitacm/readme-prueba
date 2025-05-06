part of '../bloc/dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDataEvent extends DashboardEvent {}


class LoadPostBodyEvent extends DashboardEvent {
  final int postId;

  LoadPostBodyEvent({required this.postId});

  @override
  List<Object> get props => [postId];
}