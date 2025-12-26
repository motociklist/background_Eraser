import 'package:flutter/material.dart';

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
    return DropdownButtonFormField<String>(
      initialValue: selectedProvider,
      decoration: const InputDecoration(
        labelText: 'API Provider',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.cloud),
      ),
      items: const [
        DropdownMenuItem(
          value: 'removebg',
          child: Row(
            children: [
              Icon(Icons.remove_circle_outline, size: 20),
              SizedBox(width: 8),
              Text('Remove.bg'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'photoroom',
          child: Row(
            children: [
              Icon(Icons.photo_camera, size: 20),
              SizedBox(width: 8),
              Text('PhotoRoom'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'clipdrop',
          child: Row(
            children: [
              Icon(Icons.cut, size: 20),
              SizedBox(width: 8),
              Text('Clipdrop'),
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

