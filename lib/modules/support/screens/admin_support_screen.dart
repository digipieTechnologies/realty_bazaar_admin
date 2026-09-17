// File: lib/modules/support/screens/admin_support_screen.dart
// Purpose: Main Super Admin Support module screen controller. Delegates rendering to AdminSupportDesktop or AdminSupportMobile based on screen breakpoint.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/context_ext.dart';
import '../../../providers/support/admin_support_provider.dart';
import 'admin_support_desktop.dart';
import 'admin_support_mobile.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminSupportProvider>();
      provider.fetchTickets();
      provider.subscribeToChanges();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return const AdminSupportDesktop();
    }
    return const AdminSupportMobile();
  }
}
