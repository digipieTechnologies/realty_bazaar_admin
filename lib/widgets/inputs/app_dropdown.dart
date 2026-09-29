// File: lib/widgets/inputs/app_dropdown.dart
// Purpose: Reusable Dropdown selection input field matching Admin App design system.

import 'package:realty_bazaar_admin/app/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/app_colors.dart';

class AppDropdown<T> extends StatefulWidget {
  final T? value;
  final String? label;
  final String? hint;
  final String? hintText;
  final Widget? prefixIcon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final Widget? icon;
  final bool readOnly;
  final bool isRequired;
  final FocusNode? focusNode;
  final double maxMenuHeight;
  final AutovalidateMode? autovalidateMode;

  const AppDropdown({
    super.key,
    this.value,
    this.label,
    this.hint,
    this.hintText,
    this.prefixIcon,
    required this.items,
    this.onChanged,
    this.validator,
    this.icon,
    this.focusNode,
    this.readOnly = false,
    this.isRequired = false,
    this.maxMenuHeight = 280.0,
    this.autovalidateMode,
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey<FormFieldState<T>> _formFieldKey = GlobalKey<FormFieldState<T>>();
  final GlobalKey _fieldKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  T? _selectedValue;
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_internalFocusNode ??= FocusNode());
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.value;
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_isFocused != _effectiveFocusNode.hasFocus) {
      if (mounted) {
        setState(() {
          _isFocused = _effectiveFocusNode.hasFocus;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant AppDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _selectedValue = widget.value;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _formFieldKey.currentState?.didChange(widget.value);
      });
    }
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(_handleFocusChange);
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void deactivate() {
    _closeOverlay();
    super.deactivate();
  }

  @override
  void dispose() {
    _closeOverlay();
    (widget.focusNode ?? _internalFocusNode)?.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    if (widget.readOnly || widget.items.isEmpty) return;
    if (_isOpen) {
      _closeOverlay();
    } else {
      _openOverlay();
    }
  }

  void _openOverlay() {
    _closeOverlay();

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      if (mounted) {
        setState(() {
          _isOpen = false;
        });
      }
    }
  }

  void _selectItem(DropdownMenuItem<T> item) {
    if (!item.enabled) return;
    item.onTap?.call();
    setState(() {
      _selectedValue = item.value;
    });
    _formFieldKey.currentState?.didChange(item.value);
    widget.onChanged?.call(item.value);
    _closeOverlay();
    _effectiveFocusNode.requestFocus();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final targetSize = renderBox?.size ?? Size.zero;

    return OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            // Outside barrier to dismiss
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeOverlay,
                child: const SizedBox.shrink(),
              ),
            ),
            // Floating dropdown card
            Positioned(
              width: targetSize.width > 0 ? targetSize.width : 280.0,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, targetSize.height + 6.0),
                child: Material(
                  elevation: 0,
                  color: Colors.transparent,
                  child: Container(
                    constraints: BoxConstraints(maxHeight: widget.maxMenuHeight),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: AppColors.border, width: 1.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: widget.items.map((item) {
                          final currentVal = widget.value ?? _selectedValue;
                          final isSelected = currentVal != null && currentVal == item.value;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: InkWell(
                              onTap: item.enabled ? () => _selectItem(item) : null,
                              borderRadius: BorderRadius.circular(10.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary100 : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: DefaultTextStyle(
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        child: item.child,
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_rounded, size: 18.0, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectedContent(DropdownMenuItem<T>? selectedItem, String effectiveHint) {
    if (selectedItem != null) {
      return DefaultTextStyle(
        style: AppTextStyles.body2.copyWith(color: AppColors.textPrimary, fontSize: 13.5),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        child: selectedItem.child,
      );
    }
    return Text(
      effectiveHint,
      style: AppTextStyles.body2.copyWith(color: AppColors.textMuted, fontSize: 13.5),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveHint = widget.hint ?? widget.hintText ?? '';

    return FormField<T>(
      key: _formFieldKey,
      initialValue: widget.value,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      builder: (FormFieldState<T> state) {
        final currentVal = widget.value ?? _selectedValue ?? state.value;
        DropdownMenuItem<T>? selectedItem;
        try {
          selectedItem = widget.items.cast<DropdownMenuItem<T>?>().firstWhere(
            (item) => item?.value == currentVal,
            orElse: () => null,
          );
        } catch (_) {
          selectedItem = null;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null) ...[
              RichText(
                text: TextSpan(
                  text: widget.label!,
                  style: AppTextStyles.label,
                  children: [
                    if (widget.isRequired)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6.0),
            ],
            CompositedTransformTarget(
              link: _layerLink,
              child: InkWell(
                key: _fieldKey,
                focusNode: _effectiveFocusNode,
                onFocusChange: (hasFocus) {
                  if (_isFocused != hasFocus && mounted) {
                    setState(() {
                      _isFocused = hasFocus;
                    });
                  }
                },
                onTap: widget.readOnly ? null : _toggleOverlay,
                borderRadius: BorderRadius.circular(10.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 48.0,
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  decoration: BoxDecoration(
                    color: widget.readOnly ? AppColors.surfaceLight : AppColors.surface,
                    border: Border.all(
                      color: state.hasError
                          ? AppColors.error
                          : ((_isOpen || _isFocused) ? AppColors.primary : AppColors.border),
                      width: (_isOpen || _isFocused) ? 1.5 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Row(
                    children: [
                      if (widget.prefixIcon != null) ...[widget.prefixIcon!, const SizedBox(width: 10.0)],
                      Expanded(child: _buildSelectedContent(selectedItem, effectiveHint)),
                      const SizedBox(width: 8.0),
                      widget.icon ??
                          Icon(
                            _isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 22.0,
                            color: (_isOpen || _isFocused) ? AppColors.primary : AppColors.textMuted,
                          ),
                    ],
                  ),
                ),
              ),
            ),
            if (state.hasError && state.errorText != null) ...[
              const SizedBox(height: 5.0),
              Text(state.errorText!, style: AppTextStyles.error),
            ],
          ],
        );
      },
    );
  }
}
