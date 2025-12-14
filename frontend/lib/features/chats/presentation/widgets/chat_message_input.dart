import 'package:flutter/material.dart';

class ChatMessageInput extends StatefulWidget {
  const ChatMessageInput({
    required this.onSend,
    super.key,
  });

  final Future<void> Function(String text) onSend;

  @override
  State<ChatMessageInput> createState() => _ChatMessageInputState();
}

class _ChatMessageInputState extends State<ChatMessageInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final rawText = _controller.text;
    final text = rawText.trim();

    if (text.isEmpty) {
      return;
    }

    try {
      await widget.onSend(text);
      if (!mounted) {
        return;
      }
      _controller.clear();
    } on Object {
      // TODO: показать ошибку отправки сообщения (snackbar/toast)
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Type a message…',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              heroTag: 'send_message_fab',
              onPressed: _handleSend,
              child: const Icon(Icons.send),
            ),
            const SizedBox(width: 64),
          ],
        ),
      ),
    );
  }
}
