import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Виджет для отображения изображения
class ImageDisplay extends StatelessWidget {
  final Uint8List imageBytes;
  final String title;
  final double height;

  const ImageDisplay({
    super.key,
    required this.imageBytes,
    this.title = '',
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
                height: height,
                width: double.infinity,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

