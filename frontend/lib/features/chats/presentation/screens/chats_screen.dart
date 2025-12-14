import 'package:flutter/material.dart';
import 'package:hecate/features/app/di/app_scope.dart';
import 'package:l/l.dart';
import 'package:yx_scope_flutter/yx_scope_flutter.dart';

class ChatsScreen extends StatelessWidget {
  ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopeBuilder<AppScope>.withPlaceholder(
      builder: (context, scope) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Chats'),
          ),
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final keys = await scope.bindings.interactor.getKeys();
                if (keys == null) {
                  l.w('Failed to get keys');
                  return;
                }
                l.i('pk9cPem: ${keys.pk9cPem}');
                l.i('pk9dPem: ${keys.pk9dPem}');
              },
              child: const Text('Get keys'),
            ),
          ),
        );
      },
    );
  }
}
