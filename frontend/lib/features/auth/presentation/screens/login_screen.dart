import 'package:flutter/material.dart';
import 'package:hecate/features/app/di/app_scope.dart';
import 'package:hecate/features/app/navigation/app_navigator.dart';
import 'package:hecate/features/app/navigation/app_pages.dart';
import 'package:hecate/features/auth/presentation/widgets/nickname_field.dart';
import 'package:hecate/features/auth/presentation/widgets/pin_code_field.dart';
import 'package:yx_scope_flutter/yx_scope_flutter.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopeBuilder<AppScope>.withPlaceholder(
      builder: (context, scope) {
        return _LoginScreen(scope: scope);
      },
    );
  }
}

class _LoginScreen extends StatefulWidget {
  final AppScope scope;

  _LoginScreen({
    required this.scope,
  });

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  late final TextEditingController nicknameController;
  late final TextEditingController pinController;

  @override
  void initState() {
    super.initState();
    nicknameController = TextEditingController(
      text: widget.scope.auth.stateReadable.state.nickname,
    );
    pinController = TextEditingController();
  }

  @override
  void dispose() {
    nicknameController.dispose();
    pinController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  Future<void> _onLoginButtonPressed() async {
    final nickname = nicknameController.text;
    final pin = pinController.text;

    if (nickname.isEmpty || nickname.trim() != nickname || pin.trim() != pin) {
      _showSnackBar('Please fill in all fields and remove spaces');
      return;
    }

    final nicknameTrimmed = nickname.trim();
    final pinTrimmed = pin.trim();

    try {
      await widget.scope.auth.interactor.login(
        nickname: nicknameTrimmed,
        pin: pinTrimmed,
      );
    } on Object {
      if (mounted) {
        _showSnackBar('Failed to login');
      }
      rethrow;
    }

    if (!mounted) {
      return;
    }

    AppNavigator.change(
      context,
      (state) => [
        HomePage(),
      ],
    );
  }

  void _switchToRegisterPage() {
    AppNavigator.change(
      context,
      (state) => [
        RegisterPage(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 480
                ? 400.0
                : constraints.maxWidth;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Enter your nickname and PIN to continue.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(height: 32),
                      NicknameField(controller: nicknameController),
                      SizedBox(height: 16),
                      PinCodeField(controller: pinController),
                      SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _onLoginButtonPressed,
                          child: Text('Login'),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: _switchToRegisterPage,
                        child: Text("Don't have an account? Register"),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
