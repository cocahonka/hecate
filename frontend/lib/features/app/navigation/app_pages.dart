import 'package:flutter/material.dart';
import 'package:hecate/features/auth/presentation/screens/login_screen.dart';
import 'package:hecate/features/auth/presentation/screens/register_screen.dart';
import 'package:hecate/features/home/presentation/screens/home_screen.dart';

@immutable
sealed class AppPage extends MaterialPage<void> {
  const AppPage({
    required String super.name,
    required Map<String, Object?>? super.arguments,
    required super.child,
    required LocalKey super.key,
  });

  abstract final Set<String> tags;

  @override
  Map<String, Object?> get arguments => switch (super.arguments) {
    final Map<String, Object?> args when args.isNotEmpty => args,
    _ => const <String, Object?>{},
  };

  @override
  int get hashCode => key.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppPage && key == other.key;
}

enum AppPageTag {
  needAuth,
}

final class HomePage extends AppPage {
  HomePage()
    : super(
        name: 'home',
        arguments: null,
        child: HomeScreen(),
        key: ValueKey('home'),
      );

  @override
  Set<String> get tags => {
    AppPageTag.needAuth.name,
  };
}

final class LoginPage extends AppPage {
  LoginPage()
    : super(
        name: 'login',
        arguments: null,
        child: LoginScreen(),
        key: ValueKey('login'),
      );

  @override
  Set<String> get tags => const {};
}

final class RegisterPage extends AppPage {
  RegisterPage()
    : super(
        name: 'register',
        arguments: null,
        child: RegisterScreen(),
        key: ValueKey('register'),
      );

  @override
  Set<String> get tags => const {};
}
