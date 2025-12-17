import 'package:flutter/material.dart';

class ChatMessageInput extends StatefulWidget {
  final Future<void> Function(String text) onSend;

  ChatMessageInput({
    required this.onSend,
    super.key,
  });

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

    await widget.onSend(text);
    if (!mounted) {
      return;
    }
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Type a message…',
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            FloatingActionButton.small(
              heroTag: 'send_message_fab',
              onPressed: _handleSend,
              child: Icon(Icons.send),
            ),
            SizedBox(width: 64),
          ],
        ),
      ),
    );
  }
}
