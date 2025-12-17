import 'package:flutter/material.dart';
import 'package:hecate/features/chats/domain/chats_state.dart';
import 'package:yx_state/yx_state.dart';
import 'package:yx_state_flutter/yx_state_flutter.dart';

class ChatsStatusBar extends StatelessWidget {
  final StateReadable<ChatsState> stateReadable;

  ChatsStatusBar({
    required this.stateReadable,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: StateBuilder<ChatsState>(
        stateReadable: stateReadable,
        builder: (context, state, _) {
          final (Color color, String label) = switch (state) {
            ChatsState$Loading() => (
              Colors.blue.shade400,
              'Loading chats…',
            ),
            ChatsState$Error(:final consequence) => (
              Colors.red.shade400,
              consequence ?? 'Failed to load chats',
            ),
            _ => (
              Colors.green.shade400,
              'All chats are up to date',
            ),
          };

          return Container(
            width: double.infinity,
            color: color,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }
}
