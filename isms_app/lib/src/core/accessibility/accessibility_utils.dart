import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'accessibility_provider.dart';

/// Widget that provides semantic information for screen readers
class AccessibleWidget extends ConsumerWidget {
  final Widget child;
  final String? semanticLabel;
  final String? semanticValue;
  final bool excludeSemantics;
  final bool mergeSemantics;

  const AccessibleWidget({
    super.key,
    required this.child,
    this.semanticLabel,
    this.semanticValue,
    this.excludeSemantics = false,
    this.mergeSemantics = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(accessibilitySettingsProvider);

    if (excludeSemantics || !settings.screenReaderEnabled) {
      return child;
    }

    Widget result = Semantics(
      label: semanticLabel,
      value: semanticValue,
      child: child,
    );

    if (mergeSemantics) {
      result = MergeSemantics(child: result);
    }

    return result;
  }
}

/// Widget that scales text based on accessibility settings
class ScalableText extends ConsumerWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final StrutStyle? strutStyle;
  final TextDirection? textDirection;
  final Locale? locale;
  final TextScaler? textScaler;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  const ScalableText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.strutStyle,
    this.textDirection,
    this.locale,
    this.textScaler,
    this.textWidthBasis,
    this.textHeightBehavior,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(accessibilitySettingsProvider);
    final effectiveTextScaler =
        textScaler ?? TextScaler.linear(settings.textScalingFactor);

    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      strutStyle: strutStyle,
      textDirection: textDirection,
      locale: locale,
      textScaler: effectiveTextScaler,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    );
  }
}

/// Widget that provides focus traversal for keyboard navigation
class FocusableWidget extends ConsumerWidget {
  final Widget child;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final String? semanticLabel;
  final VoidCallback? onFocusChange;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FocusableWidget({
    super.key,
    required this.child,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.semanticLabel,
    this.onFocusChange,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(accessibilitySettingsProvider);

    if (!enabled || !settings.keyboardNavigation) {
      return child;
    }

    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      onFocusChange: (hasFocus) {
        if (hasFocus && onFocusChange != null) {
          onFocusChange!();
        }
      },
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Semantics(label: semanticLabel, child: child),
      ),
    );
  }
}

/// Mixin for keyboard navigation support
mixin KeyboardNavigationMixin<T extends StatefulWidget> on State<T> {
  final FocusNode _focusNode = FocusNode();
  final List<FocusNode> _focusNodes = [];

  @override
  void dispose() {
    _focusNode.dispose();
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  FocusNode createFocusNode() {
    final node = FocusNode();
    _focusNodes.add(node);
    return node;
  }

  void focusNext() {
    final currentFocus = FocusManager.instance.primaryFocus;
    if (currentFocus != null) {
      currentFocus.nextFocus();
    }
  }

  void focusPrevious() {
    final currentFocus = FocusManager.instance.primaryFocus;
    if (currentFocus != null) {
      currentFocus.previousFocus();
    }
  }

  void handleKeyEvent(RawKeyEvent event, BuildContext context) {
    if (event is RawKeyDownEvent) {
      final logicalKey = event.logicalKey;

      if (logicalKey == LogicalKeyboardKey.tab) {
        if (event.isShiftPressed) {
          focusPrevious();
        } else {
          focusNext();
        }
      } else if (logicalKey == LogicalKeyboardKey.enter ||
          logicalKey == LogicalKeyboardKey.space) {
        final currentFocus = FocusManager.instance.primaryFocus;
        if (currentFocus != null && currentFocus.hasFocus) {
          // Simulate tap on focused widget
          final focusedWidget = currentFocus.context?.widget;
          if (focusedWidget is GestureDetector) {
            focusedWidget.onTap?.call();
          }
        }
      }
    }
  }
}

/// Extension for accessibility features
extension AccessibilityExtensions on BuildContext {
  TextTheme get accessibleTextTheme {
    final textTheme = Theme.of(this).textTheme;
    final ref = ProviderScope.containerOf(this);
    final settings = ref.read(accessibilitySettingsProvider);

    return textTheme.apply(
      bodyColor: settings.highContrastMode ? Colors.black : null,
      displayColor: settings.highContrastMode ? Colors.black : null,
    );
  }

  Color get accessibleBackgroundColor {
    final ref = ProviderScope.containerOf(this);
    final settings = ref.read(accessibilitySettingsProvider);

    return settings.highContrastMode
        ? Colors.white
        : Theme.of(this).scaffoldBackgroundColor;
  }

  Color get accessiblePrimaryColor {
    final ref = ProviderScope.containerOf(this);
    final settings = ref.read(accessibilitySettingsProvider);

    return settings.highContrastMode
        ? Colors.black
        : Theme.of(this).colorScheme.primary;
  }
}
