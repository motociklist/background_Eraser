import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Виджет для выбора API провайдера
class ProviderSelector extends StatelessWidget {
  final String selectedProvider;
  final ValueChanged<String> onChanged;

  const ProviderSelector({
    super.key,
    required this.selectedProvider,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DropdownButtonFormField<String>(
      key: ValueKey(selectedProvider),
      initialValue: selectedProvider,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.apiProvider,
        hintText: AppLocalizations.of(context)!.selectProvider,
        prefixIcon: Icon(Icons.cloud, color: colorScheme.primary),
      ),
      items: [
        DropdownMenuItem(
          value: 'removebg',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.remove_circle_outline,
                size: 18,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              const Flexible(child: Text('Remove.bg')),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'photoroom',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_camera, size: 18, color: Colors.green.shade700),
              const SizedBox(width: 8),
              const Flexible(child: Text('PhotoRoom')),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'clipdrop',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cut, size: 18, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              const Flexible(child: Text('Clipdrop')),
            ],
          ),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
