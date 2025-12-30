import 'package:flutter/material.dart';

/// Секция профиля с заголовком
class ProfileSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const ProfileSection({
    super.key,
    required this.title,
    this.icon,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

