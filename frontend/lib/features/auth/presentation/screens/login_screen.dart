import 'package:flutter/material.dart';
import 'package:hecate/features/app/di/app_scope.dart';
import 'package:yx_scope_flutter/yx_scope_flutter.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopeBuilder<AppScope>.withPlaceholder(
      builder: (context, scope) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Login'),
          ),
        );
      },
    );
  }
}
