import 'package:flutter/material.dart';
import 'package:hecate/features/app/di/app_scope.dart';
import 'package:hecate/features/chats/di/chats_scope.dart';
import 'package:hecate/features/chats/presentation/widgets/chats_list.dart';
import 'package:hecate/features/chats/presentation/widgets/chats_status_bar.dart';
import 'package:hecate/features/chats/presentation/widgets/create_chat_fab.dart';
import 'package:yx_scope_flutter/yx_scope_flutter.dart';

class ChatsScreen extends StatelessWidget {
  ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopeBuilder<AppScope>.withPlaceholder(
      builder: (context, appScope) {
        return _ChatsScopeHost(appScope: appScope);
      },
    );
  }
}

class _ChatsScopeHost extends StatefulWidget {
  const _ChatsScopeHost({
    required this.appScope,
  });

  final AppScope appScope;

  @override
  State<_ChatsScopeHost> createState() => _ChatsScopeHostState();
}

class _ChatsScopeHostState extends State<_ChatsScopeHost> {
  late final ChatsScopeHolder _holder;

  @override
  void initState() {
    super.initState();
    _holder = widget.appScope.chatsScopeHolder;
    // ignore: discarded_futures
    _holder.create();
  }

  @override
  void dispose() {
    // ignore: discarded_futures
    _holder.drop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScopeProvider<ChatsScope>(
      holder: _holder,
      child: ScopeBuilder<ChatsScope>.withPlaceholder(
        builder: (context, chatsScope) {
          return _ChatsScreen(
            scope: chatsScope,
            logout: () => widget.appScope.auth.interactor.logout(),
          );
        },
        placeholder: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _ChatsScreen extends StatefulWidget {
  const _ChatsScreen({
    required this.scope,
    required this.logout,
  });

  final ChatsScope scope;
  final VoidCallback logout;

  @override
  State<_ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<_ChatsScreen> {
  ChatsScope get _scope => widget.scope;

  @override
  Widget build(BuildContext context) {
    final stateReadable = _scope.stateReadable;
    final interactor = _scope.interactor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // ignore: discarded_futures
              interactor.updateChatsList();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: ChatsStatusBar(
            stateReadable: stateReadable,
          ),
        ),
      ),
      body: SafeArea(
        child: ChatsList(
          stateReadable: stateReadable,
          onChatTap: (chat) {
            // ignore: discarded_futures
            interactor.openChat(chatId: chat.id);
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'logout_fab',
            tooltip: 'Logout',
            onPressed: () => widget.logout(),
            child: const Icon(Icons.logout),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'refresh_chats_fab',
            tooltip: 'Refresh chats',
            onPressed: () {
              // ignore: discarded_futures
              interactor.updateChatsList();
            },
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 12),
          CreateChatFab(
            onCreateChat: ({required participantNickname}) =>
                interactor.createChat(participantNickname: participantNickname),
          ),
        ],
      ),
    );
  }
}
