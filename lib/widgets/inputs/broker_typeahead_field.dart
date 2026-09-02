// File: lib/widgets/inputs/broker_typeahead_field.dart
// Purpose: Reusable TypeAhead autocomplete selector field for Brokers.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';

import '../../app/app_colors.dart';
import '../../app/context_ext.dart';
import '../../models/broker_model.dart';
import '../../modules/brokers/services/broker_service.dart';
import '../../providers/brokers/brokers_provider.dart';

class BrokerTypeAheadField extends StatefulWidget {
  final String? selectedBrokerId;
  final ValueChanged<String?> onBrokerChanged;
  final String? label;
  final String? hintText;
  final bool isRequired;

  const BrokerTypeAheadField({
    super.key,
    required this.selectedBrokerId,
    required this.onBrokerChanged,
    this.label,
    this.hintText,
    this.isRequired = false,
  });

  @override
  State<BrokerTypeAheadField> createState() => _BrokerTypeAheadFieldState();
}

class _BrokerTypeAheadFieldState extends State<BrokerTypeAheadField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateControllerText();
  }

  @override
  void didUpdateWidget(covariant BrokerTypeAheadField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedBrokerId != widget.selectedBrokerId) {
      _updateControllerText();
    }
  }

  Future<void> _updateControllerText() async {
    final selectedId = widget.selectedBrokerId;
    if (selectedId != null && selectedId.isNotEmpty) {
      final brokers = context.read<BrokersProvider>().brokers;
      try {
        final broker = brokers.firstWhere((b) => b.id == selectedId);
        final name = (broker.businessName != null && broker.businessName!.isNotEmpty)
            ? broker.businessName!
            : (broker.id ?? 'Broker');
        final text = '$name (${broker.plan ?? "Basic"})';
        if (_controller.text != text && mounted) {
          _controller.text = text;
        }
        return;
      } catch (_) {}

      // If not in cache, fetch directly from backend
      try {
        final broker = await BrokerService().getBrokerById(id: selectedId);
        final name = (broker.businessName != null && broker.businessName!.isNotEmpty)
            ? broker.businessName!
            : (broker.id ?? 'Broker');
        final text = '$name (${broker.plan ?? "Basic"})';
        if (_controller.text != text && mounted) {
          _controller.text = text;
        }
      } catch (_) {}
    } else {
      if (_controller.text.isNotEmpty && mounted) {
        _controller.clear();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brokers = context.watch<BrokersProvider>().brokers;

    final displayLabel = widget.label ?? 'property_assign_broker_label'.tr();
    final displayHint = widget.hintText ?? 'property_broker_select_hint'.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (displayLabel.isNotEmpty) ...[
          Text(
            widget.isRequired ? '$displayLabel *' : displayLabel,
            style: context.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6.0),
        ],
        TypeAheadField<BrokerModel>(
          controller: _controller,
          builder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: context.titleSmall?.copyWith(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: displayHint,
                hintStyle: context.bodySmall?.copyWith(
                  color: isDark ? colorScheme.onSurfaceVariant : AppColors.slate400,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.person_pin_circle_outlined, size: 20.0),
                suffixIcon: widget.selectedBrokerId != null && widget.selectedBrokerId!.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _controller.clear();
                          widget.onBrokerChanged(null);
                        },
                      )
                    : const Icon(Icons.arrow_drop_down, size: 22),
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                ),
              ),
            );
          },
          suggestionsCallback: (pattern) async {
            final trimmed = pattern.trim();
            if (trimmed.isEmpty) {
              if (brokers.isNotEmpty) return brokers;
              try {
                final response = await BrokerService().fetchBrokers(page: 1, pageSize: 20);
                return response.items;
              } catch (_) {
                return brokers;
              }
            }

            try {
              final response = await BrokerService().fetchBrokers(
                search: trimmed,
                page: 1,
                pageSize: 20,
              );
              if (response.items.isNotEmpty) {
                return response.items;
              }
            } catch (_) {}

            // Client-side fallback filter over existing cached brokers
            final query = trimmed.toLowerCase();
            return brokers.where((b) {
              final name = (b.businessName ?? '').toLowerCase();
              final id = (b.id ?? '').toLowerCase();
              final plan = (b.plan ?? '').toLowerCase();
              return name.contains(query) || id.contains(query) || plan.contains(query);
            }).toList();
          },
          itemBuilder: (context, broker) {
            final name = (broker.businessName != null && broker.businessName!.isNotEmpty)
                ? broker.businessName!
                : (broker.id ?? 'Broker');
            final isSelected = broker.id == widget.selectedBrokerId;

            return ListTile(
              dense: true,
              tileColor: isSelected ? colorScheme.primary.withOpacity(0.08) : null,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'B',
                  style: TextStyle(
                    color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Plan: ${broker.plan ?? "Basic"}',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
              trailing: isSelected ? Icon(Icons.check, size: 18, color: colorScheme.primary) : null,
            );
          },
          onSelected: (broker) {
            final name = (broker.businessName != null && broker.businessName!.isNotEmpty)
                ? broker.businessName!
                : (broker.id ?? 'Broker');
            _controller.text = '$name (${broker.plan ?? "Basic"})';
            widget.onBrokerChanged(broker.id);
          },
          loadingBuilder: (context) => const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          emptyBuilder: (context) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No brokers found matching "${_controller.text}"',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}
