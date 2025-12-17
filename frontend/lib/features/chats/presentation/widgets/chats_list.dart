import 'package:flutter/material.dart';
import 'package:hecate/features/chats/domain/chats_state.dart';
import 'package:hecate/features/chats/domain/models/chat.dart';
import 'package:yx_state/yx_state.dart';
import 'package:yx_state_flutter/yx_state_flutter.dart';

class ChatsList extends StatelessWidget {
  final StateReadable<ChatsState> stateReadable;
  final void Function(Chat chat) onChatTap;

  ChatsList({
    required this.stateReadable,
    required this.onChatTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StateBuilder<ChatsState>(
      stateReadable: stateReadable,
      builder: (context, state, _) {
        final chats = state.chats;

        if (chats.isEmpty) {
          return _EmptyChatsView();
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemBuilder: (context, index) {
            final chat = chats[index];
            return _ChatTile(
              chat: chat,
              onTap: () => onChatTap(chat),
            );
          },
          separatorBuilder: (context, index) => SizedBox(height: 8),
          itemCount: chats.length,
        );
      },
    );
  }
}

class _EmptyChatsView extends StatelessWidget {
  _EmptyChatsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.7),
            ),
            SizedBox(height: 12),
            Text(
              'No chats yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to start a secure conversation by nickname.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;

  _ChatTile({
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final updatedAt = chat.updatedAt.toLocal();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          child: Text(
            chat.participantNickname.isNotEmpty
                ? chat.participantNickname[0].toUpperCase()
                : '?',
          ),
        ),
        title: Text(
          chat.participantNickname,
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Updated: ${_formatTime(updatedAt)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Icon(Icons.chevron_right),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
