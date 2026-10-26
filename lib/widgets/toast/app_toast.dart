// File: lib/widgets/toast/app_toast.dart
// Purpose: Custom Overlay toast helper for success and error status messages with ValueNotifier reactive updates.

// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_routes.dart';

enum ToastType { success, error, info, warning }

class _ToastContent {
  final String title;
  final String? description;
  final ToastType type;
  final VoidCallback? onTap;

  _ToastContent({required this.title, this.description, required this.type, this.onTap});
}

class AppToast {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;
  static ValueNotifier<_ToastContent?>? _toastNotifier;
  static AnimationController? _activeAnimationController;

  /// Show a success toast notification
  static void showSuccess(String title, [String? description]) {
    _show(title, description, ToastType.success);
  }

  /// Show an error toast notification
  static void showError(String title, [String? description]) {
    String finalTitle = title;
    String? finalDesc = description;

    final lowerTitle = title.toLowerCase();
    final lowerDesc = description?.toLowerCase() ?? '';

    if (lowerTitle.contains('payload too large') ||
        lowerTitle.contains('exceeded the maximum allowed size') ||
        lowerTitle.contains('413') ||
        lowerDesc.contains('payload too large') ||
        lowerDesc.contains('exceeded the maximum allowed size') ||
        lowerDesc.contains('413')) {
      final ctx = AppRoutes.rootNavigatorKey.currentContext;
      finalTitle = ctx != null ? ctx.tr('file_too_large') : 'File Too Large';
      finalDesc = ctx != null
          ? ctx.tr('file_too_large_desc')
          : 'The selected file size exceeds the allowed limit.';
    }

    // Automatically record user-facing error messages in diagnostic logs
    // AppLogService.instance.logWarning(
    //   'User Error Toast: $finalTitle${finalDesc != null && finalDesc.isNotEmpty ? " - $finalDesc" : ""}',
    //   tag: 'UI_TOAST',
    // );

    _show(finalTitle, finalDesc, ToastType.error);
  }

  /// Show an in-app push notification banner that drops from the top
  static void showNotification(String title, String body, {VoidCallback? onTap}) {
    _show(title, body, ToastType.info, onTap: onTap, isTop: true);
  }

  /// Dismiss active toast notification
  static void dismiss() {
    _hideWithAnimation();
  }

  static void _show(
    String title,
    String? description,
    ToastType type, {
    VoidCallback? onTap,
    bool isTop = false,
  }) {
    final content = _ToastContent(title: title, description: description, type: type, onTap: onTap);

    // If an overlay entry is currently active, update the ValueNotifier dynamically
    if (_overlayEntry != null && _toastNotifier != null) {
      _timer?.cancel();
      _toastNotifier!.value = content;
      _startTimer();
      return;
    }

    // Otherwise clean up any previous overlay entry
    _hideAbruptly();

    final overlayState = AppRoutes.rootNavigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    final notifier = ValueNotifier<_ToastContent?>(content);
    _toastNotifier = notifier;

    final entry = OverlayEntry(
      builder: (context) {
        final currentNotifier = _toastNotifier;
        if (currentNotifier == null) return const SizedBox.shrink();
        return Positioned(
          top: isTop ? 50 : null,
          bottom: isTop ? null : 50,
          left: 0,
          right: 0,
          child: _AppToastWidget(
            notifier: currentNotifier,
            onClose: dismiss,
            isTop: isTop,
            onControllerCreated: (controller) => _activeAnimationController = controller,
          ),
        );
      },
    );

    _overlayEntry = entry;
    overlayState.insert(entry);
    _startTimer();
  }

  static void _startTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 4), () {
      _hideWithAnimation();
    });
  }

  static void _hideWithAnimation() {
    _timer?.cancel();
    final controller = _activeAnimationController;
    if (controller != null && !controller.isAnimating) {
      controller
          .reverse()
          .then((_) {
            _hideAbruptly();
          })
          .catchError((_) {
            _hideAbruptly();
          });
    } else {
      _hideAbruptly();
    }
  }

  static void _hideAbruptly() {
    _timer?.cancel();
    final entry = _overlayEntry;
    if (entry != null) {
      try {
        if (entry.mounted) {
          entry.remove();
        }
      } catch (_) {}
    }
    _overlayEntry = null;
    _toastNotifier = null;
    _activeAnimationController = null;
  }
}

class _AppToastWidget extends StatefulWidget {
  final ValueNotifier<_ToastContent?> notifier;
  final VoidCallback onClose;
  final ValueChanged<AnimationController> onControllerCreated;
  final bool isTop;

  const _AppToastWidget({
    required this.notifier,
    required this.onClose,
    required this.onControllerCreated,
    this.isTop = false,
  });

  @override
  State<_AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<_AppToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    widget.onControllerCreated(_controller);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.isTop ? -0.5 : 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    widget.notifier.addListener(_onToastDataChanged);
    _controller.forward();
  }

  void _onToastDataChanged() {
    if (mounted) {
      setState(() {});
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onToastDataChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.notifier.value;
    if (content == null) return const SizedBox.shrink();

    final isError = content.type == ToastType.error;

    final isNotification = widget.isTop;
    final bgColor = isNotification ? Colors.white : (isError ? AppColors.errorLight : AppColors.successLight);
    final iconColor = isNotification ? AppColors.primary : (isError ? AppColors.error : AppColors.success);
    final iconData = isNotification
        ? Icons.notifications_active_rounded
        : (isError ? Icons.priority_high_rounded : Icons.check_rounded);

    Widget contentWidget = Material(
      color: Colors.transparent,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Decorative background shapes matching the design
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.35),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      top: -10,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icon Container
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Icon(iconData, color: iconColor, size: 20),
                          ),
                          const SizedBox(width: 16),

                          // Texts
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  content.title,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (content.description != null && content.description!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    content.description!,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Close Button
                          const SizedBox(width: 12),
                          CloseButton(onPressed: widget.onClose, color: Colors.black45),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (content.onTap != null) {
      return GestureDetector(
        onTap: () {
          widget.onClose();
          content.onTap!();
        },
        child: contentWidget,
      );
    }

    return contentWidget;
  }
}
