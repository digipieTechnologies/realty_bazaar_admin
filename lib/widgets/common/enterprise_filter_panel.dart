import 'dart:async';

import 'package:brokerflow_admin/app/common_ext.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/filters/filter_field.dart';
import '../../core/filters/filter_provider.dart';
import 'customized_dropdown.dart';

class EnterpriseFilterPanel extends StatefulWidget {
  final FilterProvider provider;
  final bool isSidebar;
  final VoidCallback? onClose;

  const EnterpriseFilterPanel({super.key, required this.provider, this.isSidebar = false, this.onClose});

  @override
  State<EnterpriseFilterPanel> createState() => _EnterpriseFilterPanelState();
}

class _EnterpriseFilterPanelState extends State<EnterpriseFilterPanel> {
  final Map<String, Timer?> _searchDebouncers = {};
  final Map<String, Completer<Iterable<FilterOption>>?> _activeCompleters = {};
  bool _isAdvancedExpanded = false;
  final Map<String, bool> _customPresetActive = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.provider.loadDynamicOptions(context);
    });
  }

  @override
  void dispose() {
    for (final timer in _searchDebouncers.values) {
      timer?.cancel();
    }
    super.dispose();
  }

  String? _getDatePreset(String? from, String? to) {
    if (from == null && to == null) return 'any';
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    if (from == todayStr && to == todayStr) {
      return 'today';
    }

    final tomorrowStr = now.add(const Duration(days: 1)).toIso8601String().substring(0, 10);
    if (from == tomorrowStr && to == tomorrowStr) {
      return 'tomorrow';
    }

    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final startOfWeek = monday.toIso8601String().substring(0, 10);
    final endOfWeek = sunday.toIso8601String().substring(0, 10);
    if (from == startOfWeek && to == endOfWeek) {
      return 'this_week';
    }

    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final startOfMonth = firstDay.toIso8601String().substring(0, 10);
    final endOfMonth = lastDay.toIso8601String().substring(0, 10);
    if (from == startOfMonth && to == endOfMonth) {
      return 'this_month';
    }

    return 'custom';
  }

  void _setDatePreset(FilterProvider provider, FilterField field, String preset) {
    setState(() {
      _customPresetActive[field.key] = false;
    });
    final fromKey = '${field.key}From';
    final toKey = '${field.key}To';
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    if (preset == 'today') {
      provider.updateDraftValue(fromKey, todayStr);
      provider.updateDraftValue(toKey, todayStr);
    } else if (preset == 'tomorrow') {
      final tomorrowStr = now.add(const Duration(days: 1)).toIso8601String().substring(0, 10);
      provider.updateDraftValue(fromKey, tomorrowStr);
      provider.updateDraftValue(toKey, tomorrowStr);
    } else if (preset == 'this_week') {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      provider.updateDraftValue(fromKey, monday.toIso8601String().substring(0, 10));
      provider.updateDraftValue(toKey, sunday.toIso8601String().substring(0, 10));
    } else if (preset == 'this_month') {
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);
      provider.updateDraftValue(fromKey, firstDay.toIso8601String().substring(0, 10));
      provider.updateDraftValue(toKey, lastDay.toIso8601String().substring(0, 10));
    } else {
      provider.clearDraftValue(fromKey);
      provider.clearDraftValue(toKey);
    }
  }

  String? _getPricePreset(double? min, double? max) {
    if (min == null && max == null) return 'any';
    if (min == 0 && max == 50000) return 'below_50k';
    if (min == 50000 && max == 100000) return '50k_1l';
    if (min == 100000 && max == 200000) return '1l_2l';
    if (min == 200000 && max == 10000000) return 'above_2l';
    return 'custom';
  }

  void _setPricePreset(FilterProvider provider, FilterField field, String preset) {
    setState(() {
      _customPresetActive[field.key] = false;
    });
    final fromKey = '${field.key}Min';
    final toKey = '${field.key}Max';

    if (preset == 'any') {
      provider.clearDraftValue(fromKey);
      provider.clearDraftValue(toKey);
    } else if (preset == 'below_50k') {
      provider.updateDraftValue(fromKey, 0.0);
      provider.updateDraftValue(toKey, 50000.0);
    } else if (preset == '50k_1l') {
      provider.updateDraftValue(fromKey, 50000.0);
      provider.updateDraftValue(toKey, 100000.0);
    } else if (preset == '1l_2l') {
      provider.updateDraftValue(fromKey, 100000.0);
      provider.updateDraftValue(toKey, 200000.0);
    } else if (preset == 'above_2l') {
      provider.updateDraftValue(fromKey, 200000.0);
      provider.updateDraftValue(toKey, 10000000.0);
    }
  }

  int _getActiveAdvancedCount(FilterProvider provider, List<FilterField> advancedFields) {
    int count = 0;
    final draftMap = provider.draftFilters.toJson();
    for (final field in advancedFields) {
      if (field.type == FilterType.dateRange) {
        if (draftMap['${field.key}From'] != null || draftMap['${field.key}To'] != null) {
          count++;
        }
      } else if (field.type == FilterType.priceRange || field.type == FilterType.numberRange) {
        if (draftMap['${field.key}Min'] != null || draftMap['${field.key}Max'] != null) {
          count++;
        }
      } else {
        if (draftMap[field.key] != null) {
          count++;
        }
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ChangeNotifierProvider.value(
      value: widget.provider,
      child: Consumer<FilterProvider>(
        builder: (context, provider, child) {
          final fields = provider.definition.fields;
          final searchFieldSupported = provider.draftFilters.toJson().containsKey('search');

          final quickFields = fields
              .where((f) => f.isQuickFilter || f.type == FilterType.quickFilter)
              .toList();
          final mainFields = fields
              .where(
                (f) =>
                    !f.isAdvanced &&
                    !f.isQuickFilter &&
                    f.type != FilterType.quickFilter &&
                    f.key != 'search',
              )
              .toList();
          final advancedFields = fields
              .where(
                (f) =>
                    f.isAdvanced && !f.isQuickFilter && f.type != FilterType.quickFilter && f.key != 'search',
              )
              .toList();

          return Material(
            elevation: 0,
            color: Colors.transparent,
            child: Container(
              width: widget.isSidebar ? MediaQuery.of(context).size.width * 0.25 : double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: widget.isSidebar ? BorderRadius.circular(12) : null,
                border: widget.isSidebar
                    ? Border.all(color: colorScheme.outlineVariant.withOpacity(0.5))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list_outlined, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'filter_options'.tr(),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        if (provider.hasChanges)
                          TextButton(onPressed: provider.reset, child: Text('reset'.tr())),
                        if (widget.onClose != null)
                          IconButton(icon: const Icon(Icons.close), onPressed: widget.onClose),
                      ],
                    ),
                  ),

                  // Fields List
                  Expanded(
                    child: provider.isLoadingOptions
                        ? const Center(child: CircularProgressIndicator())
                        : ListView(
                            padding: const EdgeInsets.all(16).copyWith(top: 0, bottom: 150),
                            children: [
                              // 1. Search Box
                              if (searchFieldSupported) ...[
                                () {
                                  final searchField = fields.firstWhere(
                                    (f) => f.key == 'search',
                                    orElse: () => const FilterField(
                                      key: 'search',
                                      type: FilterType.search,
                                      labelKey: 'Search',
                                    ),
                                  );
                                  return TextField(
                                    decoration: InputDecoration(
                                      hintText: searchField.hintText != null
                                          ? searchField.hintText!.tr()
                                          : 'common.search'.tr(),
                                      prefixIcon: const Icon(Icons.search, size: 20),
                                      suffixIcon: provider.draftFilters.toJson()['search'] != null
                                          ? IconButton(
                                              icon: const Icon(Icons.clear, size: 18),
                                              onPressed: () {
                                                provider.clearDraftValue('search');
                                              },
                                            )
                                          : null,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onChanged: (val) {
                                      provider.updateDraftValue('search', val.isNotEmpty ? val : null);
                                    },
                                  );
                                }(),
                                const SizedBox(height: 16),
                              ],

                              // 2. Quick Filters Wrapping Chips
                              if (quickFields.isNotEmpty) ...[
                                Text(
                                  'Quick Filters'.tr(),
                                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: quickFields.map((field) {
                                    final isSelected = provider.draftFilters.toJson()[field.key] == true;
                                    return FilterChip(
                                      label: Text(field.labelKey.tr()),
                                      selected: isSelected,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      color: WidgetStatePropertyAll(
                                        isSelected ? Theme.of(context).colorScheme.primary : null,
                                      ),
                                      onSelected: (selected) {
                                        provider.updateDraftValue(field.key, selected ? true : null);
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // 3. Main Fields
                              ...mainFields.map((field) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: _buildFieldWidget(context, provider, field),
                                );
                              }),

                              // 4. Advanced Fields Collapsible Section
                              if (advancedFields.isNotEmpty) ...[
                                ExpansionTile(
                                  maintainState: true,
                                  shape: const RoundedRectangleBorder(),
                                  tilePadding: const EdgeInsets.symmetric(horizontal: 0),
                                  title: Text(
                                    _getActiveAdvancedCount(provider, advancedFields) > 0
                                        ? '${"Advanced Filters".tr()} (${_getActiveAdvancedCount(provider, advancedFields)})'
                                        : 'Advanced Filters'.tr(),
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  initiallyExpanded: _isAdvancedExpanded,
                                  onExpansionChanged: (val) {
                                    setState(() {
                                      _isAdvancedExpanded = val;
                                    });
                                  },
                                  children: advancedFields.map((field) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: _buildFieldWidget(context, provider, field),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                  ),

                  // Bottom actions for modal/bottomsheet vs sidebar
                  if (!widget.isSidebar)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                provider.discardDraft();
                                if (widget.onClose != null) {
                                  widget.onClose!();
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                              child: Text('Cancel'.tr()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                provider.apply();
                                if (widget.onClose != null) {
                                  widget.onClose!();
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                              child: Text('Apply Filters'.tr()),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: provider.apply,
                          style: FilledButton.styleFrom(fixedSize: const Size.fromHeight(48)),
                          child: Text('Apply Filters'.tr()),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldWidget(BuildContext context, FilterProvider provider, FilterField field) {
    final textTheme = Theme.of(context).textTheme;
    final draftValue = provider.draftFilters.toJson()[field.key];

    switch (field.type) {
      case FilterType.search:
        return TextField(
          decoration: InputDecoration(
            hintText: field.hintText != null
                ? field.hintText!.tr()
                : "${'Search'.tr()} ${field.labelKey.tr()}",
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: provider.draftFilters.toJson()[field.key] != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      provider.clearDraftValue(field.key);
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) {
            provider.updateDraftValue(field.key, val.isNotEmpty ? val : null);
          },
        );

      case FilterType.status:
        final options = field.staticOptions ?? provider.resolvedOptions[field.key] ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.labelKey.tr(), style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('All'.tr()),
                      selected: draftValue == null,
                      onSelected: (selected) {
                        if (selected) {
                          provider.clearDraftValue(field.key);
                        }
                      },
                    ),
                  ),
                  ...options.map((opt) {
                    final isSelected = draftValue == opt.value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(opt.isPlainLabel ? opt.labelKey : opt.labelKey.tr()),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            provider.updateDraftValue(field.key, opt.value);
                          } else {
                            provider.clearDraftValue(field.key);
                          }
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );

      case FilterType.singleSelect:
        final options = field.staticOptions ?? provider.resolvedOptions[field.key] ?? [];
        return CustomizedDropdown<String?>(
          label: field.labelKey.tr(),
          value: draftValue as String?,
          items: options.map((opt) => opt.value as String?).toList(),
          showAllOption: true,
          displayValue: (val) {
            if (val == null) return 'All'.tr();
            final opt = options.firstWhere(
              (o) => o.value == val,
              orElse: () => FilterOption(value: val, labelKey: val),
            );
            return opt.isPlainLabel ? opt.labelKey : opt.labelKey.tr();
          },
          onChanged: (val) {
            if (val == null) {
              provider.clearDraftValue(field.key);
            } else {
              provider.updateDraftValue(field.key, val);
            }
          },
        );

      case FilterType.multiSelect:
        final options = field.staticOptions ?? provider.resolvedOptions[field.key] ?? [];
        final selectedList = List<String>.from(draftValue as List? ?? []);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.labelKey.tr(), style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((opt) {
                final isSelected = selectedList.contains(opt.value);
                return FilterChip(
                  label: Text(opt.isPlainLabel ? opt.labelKey : opt.labelKey.tr()),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      selectedList.add(opt.value);
                    } else {
                      selectedList.remove(opt.value);
                    }
                    provider.updateDraftValue(field.key, selectedList);
                  },
                );
              }).toList(),
            ),
          ],
        );

      case FilterType.dateRange:
        final fromKey = '${field.key}From';
        final toKey = '${field.key}To';
        final fromVal = provider.draftFilters.toJson()[fromKey] as String?;
        final toVal = provider.draftFilters.toJson()[toKey] as String?;
        final currentPreset = _customPresetActive[field.key] == true
            ? 'custom'
            : _getDatePreset(fromVal, toVal);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.labelKey.tr(), style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('All'.tr()),
                    selected: currentPreset == 'any',
                    onSelected: (selected) {
                      if (selected) _setDatePreset(provider, field, 'any');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Today'.tr()),
                    selected: currentPreset == 'today',
                    onSelected: (selected) {
                      if (selected) _setDatePreset(provider, field, 'today');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Tomorrow'.tr()),
                    selected: currentPreset == 'tomorrow',
                    onSelected: (selected) {
                      if (selected) _setDatePreset(provider, field, 'tomorrow');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('This Week'.tr()),
                    selected: currentPreset == 'this_week',
                    onSelected: (selected) {
                      if (selected) _setDatePreset(provider, field, 'this_week');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('This Month'.tr()),
                    selected: currentPreset == 'this_month',
                    onSelected: (selected) {
                      if (selected) _setDatePreset(provider, field, 'this_month');
                    },
                  ),
                ],
              ),
            ),
          ],
        );

      case FilterType.priceRange:
      case FilterType.numberRange:
        final fromKey = '${field.key}Min';
        final toKey = '${field.key}Max';
        final fromVal = (provider.draftFilters.toJson()[fromKey] as num?)?.toDouble();
        final toVal = (provider.draftFilters.toJson()[toKey] as num?)?.toDouble();
        final currentPreset = _customPresetActive[field.key] == true
            ? 'custom'
            : _getPricePreset(fromVal, toVal);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.labelKey.tr(), style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('All'.tr()),
                    selected: currentPreset == 'any',
                    onSelected: (selected) {
                      if (selected) _setPricePreset(provider, field, 'any');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('< 50k'.tr()),
                    selected: currentPreset == 'below_50k',
                    onSelected: (selected) {
                      if (selected) _setPricePreset(provider, field, 'below_50k');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('50k - 1L'.tr()),
                    selected: currentPreset == '50k_1l',
                    onSelected: (selected) {
                      if (selected) _setPricePreset(provider, field, '50k_1l');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('1L - 2L'.tr()),
                    selected: currentPreset == '1l_2l',
                    onSelected: (selected) {
                      if (selected) _setPricePreset(provider, field, '1l_2l');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('> 2L'.tr()),
                    selected: currentPreset == 'above_2l',
                    onSelected: (selected) {
                      if (selected) _setPricePreset(provider, field, 'above_2l');
                    },
                  ),
                ],
              ),
            ),
          ],
        );

      case FilterType.rangeSlider:
        final fromKey = '${field.key}Min';
        final toKey = '${field.key}Max';
        final minLimit = field.min ?? 0.0;
        final maxLimit = field.max ?? 50000000.0;

        final currentMin = (provider.draftFilters.toJson()[fromKey] as num?)?.toDouble() ?? minLimit;
        final currentMax = (provider.draftFilters.toJson()[toKey] as num?)?.toDouble() ?? maxLimit;

        final startVal = currentMin.clamp(minLimit, maxLimit);
        final endVal = currentMax.clamp(minLimit, maxLimit);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(field.labelKey.tr(), style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  '${startVal.formatIndianCurrency(compact: true)} - ${endVal.formatIndianCurrency(compact: true)}',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RangeSlider(
              values: RangeValues(startVal, endVal),
              min: minLimit,
              max: maxLimit,
              divisions: 100,
              labels: RangeLabels(
                startVal.formatIndianCurrency(compact: true),
                endVal.formatIndianCurrency(compact: true),
              ),
              onChanged: (RangeValues values) {
                if (values.start == minLimit) {
                  provider.clearDraftValue(fromKey);
                } else {
                  provider.updateDraftValue(fromKey, values.start);
                }

                if (values.end == maxLimit) {
                  provider.clearDraftValue(toKey);
                } else {
                  provider.updateDraftValue(toKey, values.end);
                }
              },
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
