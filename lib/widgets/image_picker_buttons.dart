import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Виджет кнопок для выбора изображения
class ImagePickerButtons extends StatelessWidget {
  final Function(ImageSource) onImagePicked;

  const ImagePickerButtons({super.key, required this.onImagePicked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: _ImagePickerButton(
            onPressed: () => onImagePicked(ImageSource.gallery),
            icon: Icons.photo_library,
            label: 'Галерея',
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ImagePickerButton(
            onPressed: () => onImagePicked(ImageSource.camera),
            icon: Icons.camera_alt,
            label: 'Камера',
            color: colorScheme.tertiary,
          ),
        ),
      ],
    );
  }
}

class _ImagePickerButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  const _ImagePickerButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
