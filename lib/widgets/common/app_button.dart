import 'package:flutter/material.dart';

/// Переиспользуемая кнопка приложения с градиентом
class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isDisabled = false,
    this.gradient,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveBackgroundColor =
        backgroundColor ?? colorScheme.primary;
    final effectiveForegroundColor =
        foregroundColor ?? Colors.white;
    final effectiveBorderRadius = borderRadius ?? 12.0;
    final effectivePadding = padding ??
        const EdgeInsets.symmetric(vertical: 16, horizontal: 24);

    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: isDisabled
                ? Colors.grey.shade700
                : effectiveForegroundColor,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            color: isDisabled
                ? Colors.grey.shade700
                : effectiveForegroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    if (gradient != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: isDisabled
              ? LinearGradient(
                  colors: [Colors.grey.shade400, Colors.grey.shade500],
                )
              : gradient,
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: effectiveBackgroundColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: effectivePadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(effectiveBorderRadius),
            ),
          ),
          child: buttonContent,
        ),
      );
    }

    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled
            ? Colors.grey.shade300
            : effectiveBackgroundColor,
        foregroundColor: isDisabled
            ? Colors.grey.shade700
            : effectiveForegroundColor,
        padding: effectivePadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
        ),
      ),
      child: buttonContent,
    );
  }
}

