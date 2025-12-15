import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/transport_providers.dart';

class DriversHelpersTab extends ConsumerWidget {
  const DriversHelpersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(driversProvider);
    final helpersAsync = ref.watch(helpersProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Drivers'),
              Tab(icon: Icon(Icons.support_agent), text: 'Helpers'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildDriversList(context, ref, driversAsync),
                _buildHelpersList(context, ref, helpersAsync),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriversList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<dynamic>> driversAsync,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Driver management coming soon')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Driver'),
          ),
        ),
        Expanded(
          child: driversAsync.when(
            data: (drivers) {
              if (drivers.isEmpty) {
                return const Center(child: Text('No drivers found'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: drivers.length,
                itemBuilder: (context, index) {
                  final driver = drivers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(driver.fullName),
                      subtitle: Text('License: ${driver.licenseNumber}'),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpersList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<dynamic>> helpersAsync,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Helper management coming soon')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Helper'),
          ),
        ),
        Expanded(
          child: helpersAsync.when(
            data: (helpers) {
              if (helpers.isEmpty) {
                return const Center(child: Text('No helpers found'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: helpers.length,
                itemBuilder: (context, index) {
                  final helper = helpers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.support_agent),
                      title: Text(helper.fullName),
                      subtitle: Text(helper.phoneNumber ?? 'No phone'),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }
}

