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
    required this.title,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              imageBytes,
              fit: BoxFit.contain,
              height: height,
            ),
          ),
        ),
      ],
    );
  }
}

