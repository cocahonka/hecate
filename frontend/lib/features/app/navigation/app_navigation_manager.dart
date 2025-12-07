import 'package:flutter/material.dart';
import 'package:hecate/features/app/navigation/app_navigator.dart';
import 'package:hecate/features/app/navigation/app_pages.dart';
import 'package:yx_scope/yx_scope.dart';

abstract interface class AppNavigationManager implements AsyncLifecycle {
  ValueNotifier<AppNavigationState> get controller;

  List<AppNavigationGuard> get guards;

  List<NavigatorObserver> get observers;

  Listenable? get revalidate;
}

final class AppNavigationManagerImpl implements AppNavigationManager {
  AppNavigationManagerImpl();

  @override
  final ValueNotifier<AppNavigationState> controller = ValueNotifier(
    [
      HomePage(),
    ],
  );

  @override
  List<AppNavigationGuard> get guards => [];

  @override
  List<NavigatorObserver> get observers => [];

  @override
  Listenable? get revalidate => null;

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose() async => controller.dispose();
}
