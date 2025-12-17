import 'package:flutter/material.dart';
import 'package:hecate/features/app/di/app_scope.dart';
import 'package:hecate/features/app/navigation/app_navigator.dart';
import 'package:hecate/features/app/navigation/app_pages.dart';
import 'package:hecate/features/auth/di/auth_scope.dart';
import 'package:hecate/features/auth/presentation/widgets/nickname_field.dart';
import 'package:hecate/features/auth/presentation/widgets/pin_code_field.dart';
import 'package:yx_scope_flutter/yx_scope_flutter.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopeBuilder<AppScope>.withPlaceholder(
      builder: (context, scope) {
        return _RegisterScreen(scope: scope.auth);
      },
    );
  }
}

class _RegisterScreen extends StatefulWidget {
  final AuthScope scope;

  _RegisterScreen({
    required this.scope,
  });

  @override
  State<_RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<_RegisterScreen> {
  late final TextEditingController nicknameController;
  late final TextEditingController pinController;

  @override
  void initState() {
    super.initState();
    nicknameController = TextEditingController();
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
          duration: Duration(seconds: 3),
        ),
      );
  }

  Future<void> _onRegisterButtonPressed() async {
    final nickname = nicknameController.text;
    final pin = pinController.text;

    if (nickname.isEmpty || nickname.trim() != nickname || pin.trim() != pin) {
      _showSnackBar('Please fill in all fields and remove spaces');
      return;
    }

    final nicknameTrimmed = nickname.trim();
    final pinTrimmed = pin.trim();

    final bool success;
    try {
      success = await widget.scope.interactor.register(
        nickname: nicknameTrimmed,
        pin: pinTrimmed,
      );
    } on Object {
      if (mounted) {
        _showSnackBar('Failed to register');
      }
      rethrow;
    }

    if (!mounted) {
      return;
    }

    if (!success) {
      _showSnackBar('Failed to register');
      return;
    }

    _switchToLoginPage();
  }

  void _switchToLoginPage() {
    AppNavigator.change(
      context,
      (state) => [LoginPage()],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
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
                        'Create your account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Choose a nickname and secure access with your PIN.',
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
                          onPressed: _onRegisterButtonPressed,
                          child: Text('Register'),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: _switchToLoginPage,
                        child: Text('Already have an account? Log in'),
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
