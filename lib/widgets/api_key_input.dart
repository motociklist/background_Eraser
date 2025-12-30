import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Виджет для ввода API ключа
class ApiKeyInput extends StatelessWidget {
  final TextEditingController controller;

  const ApiKeyInput({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'API Key',
        hintText: AppLocalizations.of(context)!.selectProvider,
        prefixIcon: Icon(Icons.key, color: theme.colorScheme.primary),
        suffixIcon: controller.text.isNotEmpty
            ? Icon(Icons.check_circle,
                color: Colors.green.shade600, size: 20)
            : null,
      ),
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(fontSize: 16),
    );
  }
}

