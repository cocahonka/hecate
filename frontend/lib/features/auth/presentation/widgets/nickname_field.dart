import 'package:flutter/material.dart';

class NicknameField extends StatelessWidget {
  final TextEditingController controller;

  NicknameField({
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: 'Nickname',
        hintText: 'nickname',
      ),
    );
  }
}
