// File: lib/widgets/containers/container_corner.dart
// Purpose: Reusable container with customizable borders, radius, padding, colors, gradients and tap callbacks.

import 'package:flutter/material.dart';

class ContainerCorner extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final Color? color;
  final List<Color>? colors;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Alignment? alignment;
  final VoidCallback? onTap;
  final String? tooltip;

  const ContainerCorner({
    super.key,
    this.child,
    this.width,
    this.height,
    this.color,
    this.colors,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0.0,
    this.borderRadius = 8.0,
    this.padding,
    this.margin,
    this.alignment,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Decoration decoration;
    if (colors != null && colors!.length > 1 && colors!.any((c) => c != Colors.transparent)) {
      decoration = BoxDecoration(
        gradient: LinearGradient(colors: colors!, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderWidth > 0 ? Border.all(color: borderColor, width: borderWidth) : null,
      );
    } else {
      decoration = BoxDecoration(
        color: color ?? Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderWidth > 0 ? Border.all(color: borderColor, width: borderWidth) : null,
      );
    }

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      alignment: alignment,
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      content = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: content),
      );
    }

    if (tooltip != null && tooltip!.isNotEmpty) {
      content = Tooltip(message: tooltip!, child: content);
    }

    return content;
  }
}
