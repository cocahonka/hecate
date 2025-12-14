import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hecate/features/chats/domain/chats_state.dart';
import 'package:hecate/features/chats/domain/models/message.dart';
import 'package:yx_state/yx_state.dart';
import 'package:yx_state_flutter/yx_state_flutter.dart';

class ChatMessagesList extends StatelessWidget {
  const ChatMessagesList({
    required this.stateReadable,
    required this.chatId,
    super.key,
  });

  final StateReadable<ChatsState> stateReadable;
  final String chatId;

  @override
  Widget build(BuildContext context) {
    return StateBuilder<ChatsState>(
      stateReadable: stateReadable,
      builder: (context, state, _) {
        final chat = state.chats.firstWhereOrNull(
          (chat) => chat.id == chatId,
        );

        final messages = chat?.messages;

        if (chat == null || messages == null || messages.isEmpty) {
          return const _EmptyMessagesView();
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          reverse: true,
          itemBuilder: (context, index) {
            final message = messages[messages.length - 1 - index];
            final isMine = message.nickname != chat.participantNickname;

            return _MessageBubble(
              message: message,
              isMine: isMine,
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 4),
          itemCount: messages.length,
        );
      },
    );
  }
}

class _EmptyMessagesView extends StatelessWidget {
  const _EmptyMessagesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 40,
              color: Theme.of(context).colorScheme.primary.withValues(
                alpha: 0.7,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your first end‑to‑end encrypted message in this chat.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
  });

  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = isMine
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceVariant;
    final textColor = isMine ? Colors.white : theme.colorScheme.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 360,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt.toLocal()),
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
