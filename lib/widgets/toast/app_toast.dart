// File: lib/widgets/toast/app_toast.dart
// Purpose: Overlay toast notification system for success and error alerts.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_routes.dart';

enum ToastType { success, error }

class AppToast {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;
  static final GlobalKey<_AppToastWidgetState> _toastKey = GlobalKey<_AppToastWidgetState>();

  static void showSuccess(String title, [String? description]) {
    _show(title, description, ToastType.success);
  }

  static void showError(String title, [String? description]) {
    _show(title, description, ToastType.error);
  }

  static void _show(String title, String? description, ToastType type) {
    if (_overlayEntry != null && _toastKey.currentState != null) {
      _timer?.cancel();
      _toastKey.currentState?.updateContent(title, description, type);
      _startTimer();
      return;
    }

    _hideAbruptly();

    final overlayState = AppRoutes.rootNavigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50,
        left: 0,
        right: 0,
        child: _AppToastWidget(
          key: _toastKey,
          initialTitle: title,
          initialDescription: description,
          initialType: type,
          onClose: _hideWithAnimation,
        ),
      ),
    );

    overlayState.insert(_overlayEntry!);
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
    if (_toastKey.currentState != null) {
      _toastKey.currentState!.reverseAnimation().then((_) {
        _hideAbruptly();
      });
    } else {
      _hideAbruptly();
    }
  }

  static void _hideAbruptly() {
    _timer?.cancel();
    if (_overlayEntry?.mounted ?? false) {
      _overlayEntry?.remove();
    }
    _overlayEntry = null;
  }
}

class _AppToastWidget extends StatefulWidget {
  final String initialTitle;
  final String? initialDescription;
  final ToastType initialType;
  final VoidCallback onClose;

  const _AppToastWidget({
    super.key,
    required this.initialTitle,
    this.initialDescription,
    required this.initialType,
    required this.onClose,
  });

  @override
  State<_AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<_AppToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late String _title;
  late String? _description;
  late ToastType _type;

  @override
  void initState() {
    super.initState();
    _title = widget.initialTitle;
    _description = widget.initialDescription;
    _type = widget.initialType;

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  void updateContent(String newTitle, String? newDesc, ToastType newType) {
    setState(() {
      _title = newTitle;
      _description = newDesc;
      _type = newType;
    });
    _controller.forward(from: 0.0);
  }

  Future<void> reverseAnimation() async {
    if (mounted) {
      await _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isError = _type == ToastType.error;
    final bgColor = isError ? const Color(0xFFFDD4D7) : const Color(0xFFCEF4D8);
    final iconColor = isError ? const Color(0xFFE53935) : const Color(0xFF388E3C);
    final iconData = isError ? Icons.priority_high_rounded : Icons.check_rounded;

    return Material(
      color: Colors.transparent,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(iconData, color: iconColor, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _title,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (_description != null && _description!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                _description!,
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
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.close_rounded, color: Colors.black38, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
