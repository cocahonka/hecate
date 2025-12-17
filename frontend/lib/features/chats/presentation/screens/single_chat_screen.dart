import 'package:flutter/material.dart';
import 'package:hecate/features/app/di/app_scope.dart';
import 'package:hecate/features/chats/di/chats_scope.dart';
import 'package:hecate/features/chats/presentation/widgets/chat_message_input.dart';
import 'package:hecate/features/chats/presentation/widgets/chat_messages_list.dart';
import 'package:yx_scope_flutter/yx_scope_flutter.dart';

class SingleChatScreen extends StatelessWidget {
  final String chatId;

  const SingleChatScreen({
    required this.chatId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ScopeBuilder<AppScope>.withPlaceholder(
      builder: (context, appScope) {
        return ScopeProvider<ChatsScope>(
          holder: appScope.chatsScopeHolder,
          child: ScopeBuilder<ChatsScope>.withPlaceholder(
            builder: (context, chatsScope) {
              return _SingleChatScreen(
                scope: chatsScope,
                chatId: chatId,
              );
            },
            placeholder: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
      placeholder: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _SingleChatScreen extends StatefulWidget {
  const _SingleChatScreen({
    required this.scope,
    required this.chatId,
  });

  final ChatsScope scope;
  final String chatId;

  @override
  State<_SingleChatScreen> createState() => _SingleChatScreenState();
}

class _SingleChatScreenState extends State<_SingleChatScreen> {
  ChatsScope get _scope => widget.scope;

  @override
  Widget build(BuildContext context) {
    final stateReadable = _scope.stateReadable;
    final interactor = _scope.interactor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // ignore: discarded_futures
            interactor.closeChat(chatId: widget.chatId);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatMessagesList(
              stateReadable: stateReadable,
              chatId: widget.chatId,
            ),
          ),
          ChatMessageInput(
            onSend: (text) => interactor.sendMessage(
              chatId: widget.chatId,
              messagePlaintext: text,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'refresh_chat_messages_fab_${widget.chatId}',
        tooltip: 'Refresh messages',
        onPressed: () {
          // ignore: discarded_futures
          interactor.updateMessages(chatId: widget.chatId);
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
