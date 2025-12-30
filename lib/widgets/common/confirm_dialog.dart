import 'package:flutter/material.dart';

/// Переиспользуемый диалог подтверждения
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final IconData? icon;
  final Color? iconColor;
  final Color? confirmButtonColor;
  final VoidCallback? onConfirm;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Подтвердить',
    this.cancelText = 'Отмена',
    this.icon,
    this.iconColor,
    this.confirmButtonColor,
    this.onConfirm,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Подтвердить',
    String cancelText = 'Отмена',
    IconData? icon,
    Color? iconColor,
    Color? confirmButtonColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        icon: icon,
        iconColor: iconColor,
        confirmButtonColor: confirmButtonColor,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(title),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () {
            if (onConfirm != null) {
              onConfirm!();
            } else {
              Navigator.of(context).pop(true);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmButtonColor ?? Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}

