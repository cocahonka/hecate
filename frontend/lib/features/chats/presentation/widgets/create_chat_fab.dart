import 'package:flutter/material.dart';

class CreateChatFab extends StatelessWidget {
  final Future<void> Function({
    required String participantNickname,
  })
  onCreateChat;

  CreateChatFab({
    required this.onCreateChat,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateChatDialog(context),
      icon: Icon(Icons.add_comment),
      label: Text('New chat'),
    );
  }

  Future<void> _showCreateChatDialog(BuildContext context) async {
    final controller = TextEditingController();

    final theme = Theme.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Start new chat'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Participant nickname',
              hintText: 'Enter nickname',
            ),
            textInputAction: TextInputAction.done,
            autofocus: true,
            onSubmitted: (_) => Navigator.of(context).pop(true),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Create'),
            ),
          ],
        );
      },
    );

    if (!context.mounted || result != true) {
      return;
    }

    final rawNickname = controller.text;
    final nickname = rawNickname.trim();

    if (nickname.isEmpty || nickname != rawNickname) {
      _showSnackBar(
        context,
        'Please enter a valid nickname without leading/trailing spaces',
        theme,
      );
      return;
    }

    await onCreateChat(participantNickname: nickname);
  }

  void _showSnackBar(
    BuildContext context,
    String message,
    ThemeData theme,
  ) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}
