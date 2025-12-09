import 'package:flutter/material.dart';
import 'package:hecate/features/app/di/app_scope.dart';
import 'package:hecate/features/app/navigation/app_navigator.dart';
import 'package:hecate/features/app/navigation/app_pages.dart';
import 'package:hecate/features/auth/domain/auth_state.dart';
import 'package:yx_scope/yx_scope.dart';
import 'package:yx_scope_flutter/yx_scope_flutter.dart';

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
  List<AppNavigationGuard> get guards => [
    (context, state) {
      final authState = ScopeProvider.scopeHolderOf<AppScope>(
        context,
        listen: false,
      ).scope!.auth.stateReadable.state;

      final needsAuth = state.any(
        (page) => page.tags.contains(AppPageTag.needAuth.name),
      );

      return switch (authState) {
        AuthState$Unauthenticated() when needsAuth => [
          if (authState.nickname == null) RegisterPage() else LoginPage(),
        ],
        _ => state,
      };
    },
  ];

  @override
  List<NavigatorObserver> get observers => [];

  @override
  Listenable? get revalidate => null;

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose() async => controller.dispose();
}
