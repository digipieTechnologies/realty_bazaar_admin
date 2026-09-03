// File: lib/modules/leads/screens/lead_detail_screen.dart
// Purpose: Screen controller for Lead Details, fetches lead by ID if needed and delegates to desktop/mobile views.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/context_ext.dart';
import '../../../models/social_lead_model.dart';
import '../../../providers/leads/admin_leads_provider.dart';
import 'lead_detail_desktop.dart';
import 'lead_detail_mobile.dart';

class LeadDetailScreen extends StatefulWidget {
  final String? leadId;
  final SocialLeadModel? lead;

  const LeadDetailScreen({super.key, this.leadId, this.lead});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  SocialLeadModel? _lead;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.lead != null) {
      _lead = widget.lead;
    } else if (widget.leadId != null && widget.leadId!.isNotEmpty) {
      _loadLead();
    }
  }

  @override
  void didUpdateWidget(covariant LeadDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lead != oldWidget.lead && widget.lead != null) {
      _lead = widget.lead;
    }
  }

  Future<void> _loadLead() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetched = await context.read<AdminLeadsProvider>().fetchLeadById(widget.leadId!);
      if (mounted) {
        setState(() {
          _lead = fetched;
          _isLoading = false;
          if (fetched == null) {
            _errorMessage = 'no_data'.tr();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final provider = context.watch<AdminLeadsProvider>();
    final targetId = _lead?.id ?? widget.leadId;
    SocialLeadModel? liveLead;
    if (targetId != null) {
      if (provider.selectedLead?.id == targetId) {
        liveLead = provider.selectedLead;
      } else {
        for (final l in provider.leads) {
          if (l.id == targetId) {
            liveLead = l;
            break;
          }
        }
      }
    }
    final lead = liveLead ?? _lead;

    if (_errorMessage != null || lead == null) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(title: Text('leads_detail_title'.tr())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'no_data'.tr(), style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: Text('cancel'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    final displayLead = lead;

    if (context.isDesktop) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        body: LeadDetailDesktop(lead: displayLead),
      );
    }

    return LeadDetailMobile(lead: displayLead);
  }
}
