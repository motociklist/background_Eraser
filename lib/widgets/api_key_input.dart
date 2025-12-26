import 'package:flutter/material.dart';

/// Виджет для ввода API ключа
class ApiKeyInput extends StatelessWidget {
  final TextEditingController controller;

  const ApiKeyInput({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'API Key',
        hintText: 'Enter your API key',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.key),
      ),
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
    );
  }
}

