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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: _GradientButton(
            onPressed: isProcessing ? null : onRemoveBackground,
            icon: Icons.auto_fix_high,
            label: 'Удалить фон',
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
            isDisabled: isProcessing,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GradientButton(
            onPressed: isProcessing ? null : onBlurBackground,
            icon: Icons.blur_on,
            label: 'Размыть фон',
            gradient: LinearGradient(
              colors: [Colors.purple.shade600, Colors.purple.shade400],
            ),
            isDisabled: isProcessing,
          ),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Gradient gradient;
  final bool isDisabled;

  const _GradientButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.gradient,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDisabled ? null : gradient,
        color: isDisabled ? Colors.grey.shade300 : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: isDisabled ? Colors.grey : Colors.white),
        label: Text(
          label,
          style: TextStyle(
            color: isDisabled ? Colors.grey.shade700 : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
