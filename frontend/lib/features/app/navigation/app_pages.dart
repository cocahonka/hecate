import 'package:flutter/material.dart';
import 'package:hecate/features/auth/presentation/screens/login_screen.dart';
import 'package:hecate/features/auth/presentation/screens/register_screen.dart';
import 'package:hecate/features/chats/presentation/screens/chats_screen.dart';
import 'package:hecate/features/chats/presentation/screens/single_chat_screen.dart';

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

final class ChatsPage extends AppPage {
  ChatsPage()
    : super(
        name: 'chats',
        arguments: null,
        child: ChatsScreen(),
        key: ValueKey('home'),
      );

  @override
  Set<String> get tags => {
    AppPageTag.needAuth.name,
  };
}

final class SingleChatPage extends AppPage {
  SingleChatPage({
    required String chatId,
  }) : super(
         name: 'single_chat',
         arguments: {
           'chatId': chatId,
         },
         child: SingleChatScreen(
           chatId: chatId,
         ),
         key: ValueKey('single_chat'),
       );

  @override
  Set<String> get tags => {
    AppPageTag.needAuth.name,
  };
}
