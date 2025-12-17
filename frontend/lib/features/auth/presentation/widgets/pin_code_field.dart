import 'package:flutter/material.dart';

class PinCodeField extends StatelessWidget {
  final TextEditingController controller;

  PinCodeField({
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'PIN',
        hintText: '123456',
      ),
      obscureText: true,
    );
  }
}
