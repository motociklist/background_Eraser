import 'package:flutter/material.dart';

/// Виджет кнопок обработки изображения
class ProcessButtons extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onRemoveBackground;
  final VoidCallback onBlurBackground;

  const ProcessButtons({
    super.key,
    required this.isProcessing,
    required this.onRemoveBackground,
    required this.onBlurBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isProcessing ? null : onRemoveBackground,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Remove Background'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isProcessing ? null : onBlurBackground,
            icon: const Icon(Icons.blur_on),
            label: const Text('Blur Background'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

