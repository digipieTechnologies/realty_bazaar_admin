import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomizedDropdown<T> extends FormField<T?> {
  final String label;
  final String? hintText;
  final List<T> items;
  final String Function(T) displayValue;
  final Widget Function(BuildContext, T)? itemBuilder;
  final ValueChanged<T?>? onChanged;
  @override
  final bool enabled;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? contentPadding;
  final bool showAllOption;
  final bool isFloatingLabel;
  final Color? fillColor;
  final T? value;
  final bool requestFocusOnTap;
  final bool isBusy;
  final bool Function(T)? isPinned;
  final bool enableSearch;

  CustomizedDropdown({
    super.key,
    required this.label,
    this.value,
    required this.items,
    required this.displayValue,
    this.isPinned,
    this.itemBuilder,
    this.hintText,
    this.onChanged,
    this.enabled = true,
    this.constraints,
    this.contentPadding,
    this.showAllOption = true,
    this.isFloatingLabel = false,
    this.isBusy = false,
    this.requestFocusOnTap = true,
    this.enableSearch = true,
    this.fillColor,
    super.validator,
    super.onSaved,
  }) : super(
         initialValue: value,
         builder: (FormFieldState<T?> field) {
           final state = field as _CustomizedDropdownState<T>;
           final context = state.context;

           final theme = Theme.of(context);
           final colorScheme = theme.colorScheme;

           state.prepareItemKeys();

           final inputDecorationTheme = InputDecorationTheme(
             filled: true,
             fillColor: fillColor ?? colorScheme.surface,
             hintStyle: theme.textTheme.bodySmall?.copyWith(
               color: colorScheme.onSurfaceVariant,
               fontSize: 14,
             ),
             contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
             enabledBorder: OutlineInputBorder(
               borderRadius: BorderRadius.circular(12),
               borderSide: BorderSide(color: colorScheme.outlineVariant),
             ),
             disabledBorder: OutlineInputBorder(
               borderRadius: BorderRadius.circular(12),
               borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
             ),
             focusedBorder: OutlineInputBorder(
               borderRadius: BorderRadius.circular(12),
               borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
             ),
           );

           if (isBusy) {
             return Column(
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: [
                 if (label.trim().isNotEmpty) ...[
                   Text(
                     label,
                     style: theme.textTheme.titleSmall?.copyWith(
                       color: enabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.38),
                       fontWeight: FontWeight.w600,
                     ),
                   ),
                   const SizedBox(height: 8),
                 ],
                 Container(
                   height: 48,
                   decoration: BoxDecoration(
                     color: inputDecorationTheme.fillColor,
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: colorScheme.outlineVariant),
                   ),
                   child: const Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
                 ),
               ],
             );
           }

           final dropdownMenu = LayoutBuilder(
             builder: (context, constraints) {
               return KeyboardListener(
                 focusNode: state.keyboardFocusNode,
                 onKeyEvent: state.handleKeyNavigation,
                 child: DropdownMenu<T?>(
                   key: state.dropdownKey,
                   controller: state.controller,
                   initialSelection: state.value,
                   expandedInsets: EdgeInsets.zero,
                   enabled: enabled,
                   width: constraints.maxWidth + 7,
                   requestFocusOnTap: enableSearch ? requestFocusOnTap : false,
                   enableSearch: enableSearch,
                   enableFilter: enableSearch,
                   menuHeight: 400,
                   closeBehavior: DropdownMenuCloseBehavior.all,
                   label: isFloatingLabel ? Text(label) : null,
                   hintText: !isFloatingLabel ? hintText : null,
                   onSelected: (newValue) {
                     state.didChange(newValue);
                     if (enabled) onChanged?.call(newValue);
                   },
                   textStyle: theme.textTheme.titleMedium?.copyWith(
                     fontSize: 16,
                     color: enabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.20),
                   ),
                   trailingIcon: Icon(
                     Icons.keyboard_arrow_down_rounded,
                     color: enabled ? colorScheme.onSurfaceVariant : colorScheme.onSurface.withOpacity(0.20),
                   ),
                   selectedTrailingIcon: Icon(
                     Icons.keyboard_arrow_up_rounded,
                     color: enabled ? colorScheme.onSurfaceVariant : colorScheme.onSurface.withOpacity(0.20),
                   ),
                   inputDecorationTheme: inputDecorationTheme,
                   menuStyle: MenuStyle(
                     backgroundColor: WidgetStateProperty.all(colorScheme.surface),
                     elevation: WidgetStateProperty.all(8),
                     padding: WidgetStateProperty.all(const EdgeInsets.only(top: 6, bottom: 6)),
                     shape: WidgetStateProperty.all(
                       RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     ),
                   ),
                   dropdownMenuEntries: () {
                     final pinnedItems = <T>[];
                     final unpinnedItems = <T>[];

                     final isPinnedFn = isPinned;
                     if (isPinnedFn != null) {
                       for (final item in items) {
                         if (isPinnedFn(item)) {
                           pinnedItems.add(item);
                         } else {
                           unpinnedItems.add(item);
                         }
                       }
                     } else {
                       unpinnedItems.addAll(items);
                     }

                     final sortedItems = [...pinnedItems, ...unpinnedItems];

                     return [
                       if (showAllOption)
                         DropdownMenuEntry<T?>(
                           value: null,
                           label: 'common.all'.tr(),
                           style: _menuItemStyle(context),
                         ),
                       ...sortedItems.map((item) {
                         final pinned = isPinned?.call(item) ?? false;
                         return DropdownMenuEntry<T?>(
                           value: item,
                           label: displayValue(item),
                           labelWidget: itemBuilder != null ? itemBuilder(context, item) : null,
                           trailingIcon: pinned
                               ? Icon(Icons.push_pin_rounded, size: 16, color: colorScheme.primary)
                               : const SizedBox(),
                           style: _menuItemStyle(context),
                         );
                       }),
                     ];
                   }(),
                 ),
               );
             },
           );

           Widget mainContent;

           if (isFloatingLabel && !state.hasError) {
             mainContent = dropdownMenu;
           } else {
             mainContent = Column(
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: [
                 if (label.trim().isNotEmpty) ...[
                   Text(
                     label,
                     style: theme.textTheme.titleSmall?.copyWith(
                       color: enabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.38),
                       fontWeight: FontWeight.w600,
                     ),
                   ),
                   const SizedBox(height: 8),
                 ],
                 dropdownMenu,
               ],
             );
           }

           if (constraints != null) {
             return ConstrainedBox(constraints: constraints, child: mainContent);
           }

           return mainContent;
         },
       );

  @override
  FormFieldState<T?> createState() => _CustomizedDropdownState<T>();

  static ButtonStyle _menuItemStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size(double.infinity, 48)),
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused) || states.contains(WidgetState.hovered)) {
          return colorScheme.primary.withOpacity(0.08);
        }
        return Colors.transparent;
      }),
    );
  }
}

class _CustomizedDropdownState<T> extends FormFieldState<T?> {
  late final TextEditingController controller;

  final GlobalKey dropdownKey = GlobalKey();
  final FocusNode keyboardFocusNode = FocusNode();

  final List<GlobalKey> itemKeys = [];
  int focusedIndex = 0;

  @override
  CustomizedDropdown<T> get widget => super.widget as CustomizedDropdown<T>;

  void prepareItemKeys() {
    final total = widget.items.length + (widget.showAllOption ? 1 : 0);

    if (itemKeys.length != total) {
      itemKeys
        ..clear()
        ..addAll(List.generate(total, (_) => GlobalKey()));
    }
  }

  void handleKeyNavigation(KeyEvent event) {
    final total = itemKeys.length;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      focusedIndex = (focusedIndex + 1).clamp(0, total - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      focusedIndex = (focusedIndex - 1).clamp(0, total - 1);
    } else {
      return;
    }

    final ctx = itemKeys[focusedIndex].currentContext;

    if (ctx != null) {
      Scrollable.ensureVisible(ctx, alignment: 0.5, duration: const Duration(milliseconds: 120));
    }
  }

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((timestamp) {
      _updateController();
    });
  }

  void _updateController() {
    final String text;
    if (value == null) {
      if (widget.showAllOption) {
        text = 'All';
      } else {
        text = '';
      }
    } else {
      text = widget.displayValue(value as T);
    }
    controller.value = TextEditingValue(text: text, selection: const TextSelection.collapsed(offset: 0));
  }

  @override
  void didUpdateWidget(CustomizedDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    setValue(widget.value);
    _updateController();
  }

  @override
  void didChange(T? value) {
    super.didChange(value);
    _updateController();
  }

  @override
  void dispose() {
    controller.dispose();
    keyboardFocusNode.dispose();
    super.dispose();
  }
}
