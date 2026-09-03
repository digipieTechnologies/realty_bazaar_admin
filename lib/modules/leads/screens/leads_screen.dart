// File: lib/modules/leads/screens/leads_screen.dart
// Purpose: Super Admin Leads screen controller. Owns filter state and delegates UI layout to LeadsDesktop or LeadsMobile.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/context_ext.dart';
import '../../../core/filters/filter_provider.dart';
import '../../../providers/leads/admin_leads_provider.dart';
import '../../../widgets/common/enterprise_filter_panel.dart';
import '../models/lead_filter_model.dart';
import 'leads_desktop.dart';
import 'leads_mobile.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => LeadsScreenState();
}

class LeadsScreenState extends State<LeadsScreen> {
  late final FilterProvider<LeadFilterModel> filterProvider;
  bool showFilterSidebar = false;

  AdminLeadsProvider get leadsProv => context.watch<AdminLeadsProvider>();

  @override
  void initState() {
    super.initState();
    filterProvider = FilterProvider<LeadFilterModel>(
      definition: LeadFilterModel.filterDefinition,
      initialFilters: const LeadFilterModel(),
      onApply: () {
        final active = filterProvider.activeFilters;
        context.read<AdminLeadsProvider>().updateFilter(active);
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminLeadsProvider>();
      provider.fetchBrokers();
      provider.fetchLeads();
    });
  }

  @override
  void dispose() {
    filterProvider.dispose();
    super.dispose();
  }

  void toggleFilterSidebar() {
    setState(() {
      showFilterSidebar = !showFilterSidebar;
    });
  }

  void showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnterpriseFilterPanel(
        provider: filterProvider,
        isSidebar: false,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return LeadsDesktop(state: this);
    }
    return LeadsMobile(state: this);
  }
}
