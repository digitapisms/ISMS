import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../school_registration/application/school_providers.dart';
import 'tabs/general_info_tab.dart';
import 'tabs/branding_tab.dart';
import 'tabs/subscription_tab.dart';
import 'tabs/school_code_tab.dart';
import 'tabs/payment_settings_tab.dart';

class SchoolSettingsScreen extends ConsumerStatefulWidget {
  const SchoolSettingsScreen({super.key});

  @override
  ConsumerState<SchoolSettingsScreen> createState() =>
      _SchoolSettingsScreenState();
}

class _SchoolSettingsScreenState extends ConsumerState<SchoolSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schoolAsync = ref.watch(currentSchoolProvider);
    final schoolId = schoolAsync?.id;

    if (schoolId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('School Settings')),
        body: const Center(child: Text('No school context available')),
      );
    }

    final schoolDataAsync = ref.watch(schoolProvider(schoolId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('School Settings'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'General Info'),
            Tab(icon: Icon(Icons.palette_outlined), text: 'Branding'),
            Tab(icon: Icon(Icons.workspace_premium), text: 'Subscription'),
            Tab(icon: Icon(Icons.payments_outlined), text: 'Payments'),
            Tab(icon: Icon(Icons.vpn_key), text: 'School Code'),
          ],
        ),
      ),
      body: schoolDataAsync.when(
        data: (school) {
          if (school == null) {
            return const Center(child: Text('School not found'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              GeneralInfoTab(school: school),
              BrandingTab(school: school),
              SubscriptionTab(school: school),
              PaymentSettingsTab(school: school),
              SchoolCodeTab(school: school),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading school information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '$e',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(schoolProvider(schoolId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
