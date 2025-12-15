import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'school_branding.dart';

/// Widget to display school logo and name
class SchoolBrandingWidget extends ConsumerWidget {
  const SchoolBrandingWidget({
    super.key,
    this.showLogo = true,
    this.showName = true,
    this.logoSize = 40,
    this.textStyle,
  });

  final bool showLogo;
  final bool showName;
  final double logoSize;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(schoolBrandingProvider);
    final theme = Theme.of(context);

    if (!showLogo && !showName) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLogo && branding.logoUrl != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                branding.logoUrl!,
                width: logoSize,
                height: logoSize,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.school,
                    size: logoSize * 0.6,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        if (showName)
          Flexible(
            child: Text(
              branding.schoolName ?? 'ILMA Cloud Portal',
              style: textStyle ??
                  theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

