import 'dart:io';

import 'package:brokerflow_admin/app/common_ext.dart';
import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:brokerflow_admin/models/media_model.dart';
import 'package:brokerflow_admin/widgets/media/full_screen_media_viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CachedImage extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackUrl;
  final double height;
  final double width;
  final BoxFit fit;
  final bool isLocal;
  final bool ignoring;
  final Color? borderColor;
  final WidgetBuilder? placeholderWidget;
  final WidgetBuilder? errorWidget;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const CachedImage({
    super.key,
    this.imageUrl,
    double? radius,
    this.isLocal = false,
    double? height,
    double? width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackUrl,
    this.borderColor,
    this.ignoring = false,
    this.placeholderWidget,
    this.errorWidget,
    this.backgroundColor,
  }) : height = height ?? radius ?? 50.0,
       width = width ?? radius ?? 50.0;

  @override
  Widget build(BuildContext context) {
    String placeholder = 'assets/logo/app_logo.png';

    Widget placeHolderWidget = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: backgroundColor ?? context.theme.colorScheme.surfaceContainerLow,
        borderRadius: borderRadius ?? BorderRadius.circular(5),
      ),
      padding: EdgeInsets.all(height * 0.15),
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          0.4,
          0,
        ]),
        child: Image.asset('assets/logo/app_logo.png', fit: BoxFit.contain),
      ),
    );

    if (fallbackUrl != null && fallbackUrl != "") {
      placeHolderWidget = CachedImage(
        imageUrl: fallbackUrl,
        width: width,
        height: height,
        fit: fit,
        borderRadius: borderRadius ?? BorderRadius.circular(5),
        isLocal: isLocal,
      );
    }

    try {
      if (isLocal) {
        return Opacity(
          opacity: 0.5,
          child: Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              color: backgroundColor ?? context.theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.4),
              shape: BoxShape.rectangle,
              borderRadius: borderRadius ?? BorderRadius.circular(5),
              image: DecorationImage(image: AssetImage(placeholder), fit: BoxFit.cover),
            ),
            child: ClipOval(
              child: Image.file(File(imageUrl!), fit: fit, height: height, width: width),
            ),
          ),
        );
      }

      if (imageUrl == null || imageUrl == "" || imageUrl == "null" || !imageUrl!.startsWith("http")) {
        if (errorWidget != null) return errorWidget?.call(context) ?? placeHolderWidget;
        if (placeholderWidget != null) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: backgroundColor ?? context.theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.4),
              border: borderColor != null ? Border.all(color: borderColor!) : null,
              borderRadius: borderRadius ?? BorderRadius.circular(5),
            ),
            child: placeholderWidget?.call(context),
          );
        }

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? context.theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.4),
            border: borderColor != null ? Border.all(color: borderColor!) : null,
            borderRadius: borderRadius ?? BorderRadius.circular(5),
          ),
          child: placeHolderWidget,
        );
      }

      final imageChild = Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: backgroundColor, // Avoid fallback color to prevent thin border bleeding effect
          border: borderColor != null ? Border.all(color: borderColor!) : null,
          borderRadius: borderRadius ?? BorderRadius.circular(5),
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(5),
          child: CachedNetworkImage(
            imageUrl: imageUrl ?? 'assets/logo/app_logo.png',
            fit: fit,
            height: height,
            width: width,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (context, url) => placeholderWidget?.call(context) ?? placeHolderWidget,
            errorWidget: (context, url, error) => errorWidget?.call(context) ?? placeHolderWidget,
            imageBuilder: (context, imageProvider) {
              final img = Image(image: imageProvider, fit: fit, height: height, width: width);
              if (ignoring) return img;
              return GestureDetector(
                onTap: () {
                  if (imageUrl != null && imageUrl != "") {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (context) => FullScreenMediaViewer(
                          medias: [MediaModel(url: imageUrl!, type: 'image')],
                        ),
                      ),
                    );
                  }
                },
                behavior: HitTestBehavior.deferToChild,
                child: img,
              );
            },
            imageRenderMethodForWeb: !kIsWeb
                ? ImageRenderMethodForWeb.HtmlImage
                : ImageRenderMethodForWeb.HttpGet,
          ),
        ),
      );

      return imageChild;
    } catch (e) {
      return Opacity(
        opacity: 0.5,
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: backgroundColor ?? context.theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.4),
            shape: BoxShape.rectangle,
            borderRadius: borderRadius ?? BorderRadius.circular(5),
          ),
          child: Opacity(
            opacity: 0.5,
            child: Icon(
              Icons.broken_image_outlined,
              size: (height < width ? height : width) * 0.5,
              color: context.theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
  }
}

class CircleImage extends StatelessWidget {
  final String? image;
  final double radius;
  final VoidCallback? onTap;
  final bool? ignoring;

  const CircleImage({super.key, required this.radius, this.onTap, this.image, this.ignoring});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: CachedImage(
          imageUrl: image,
          radius: radius,
          ignoring: ignoring ?? false,
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }
}

class CachedImageInitials extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double? width;
  final double? height;
  final double? radius;

  const CachedImageInitials({super.key, this.imageUrl, this.initials, this.width, this.height, this.radius});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = width ?? 30;
    final h = height ?? 30;
    final fontSize = (w + h) * 0.2;
    return CachedImage(
      width: w,
      height: h,
      imageUrl: imageUrl,
      borderRadius: BorderRadius.circular(radius ?? 12),
      backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
      placeholderWidget: (context) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(radius ?? 12),
        ),
        child: Center(
          child: Text(
            initials?.forImage() ?? "-",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.primary,
              fontSize: fontSize,
            ),
          ),
        ),
      ),
      errorWidget: (context) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(radius ?? 12),
        ),
        child: Center(
          child: Text(
            initials?.forImage() ?? "-",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.primary,
              fontSize: fontSize,
            ),
          ),
        ),
      ),
    );
  }
}
