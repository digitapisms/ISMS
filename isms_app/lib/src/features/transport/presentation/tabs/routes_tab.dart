import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/transport_providers.dart';

class RoutesTab extends ConsumerWidget {
  const RoutesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(routesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Routes',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Route management coming soon')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Route'),
              ),
            ],
          ),
        ),
        Expanded(
          child: routesAsync.when(
            data: (routes) {
              if (routes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.route_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No routes found',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: routes.length,
                itemBuilder: (context, index) {
                  final route = routes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.route),
                      title: Text(route.routeName),
                      subtitle: Text('${route.startLocation} → ${route.endLocation}'),
                      trailing: route.isActive
                          ? const Chip(label: Text('Active'), backgroundColor: Colors.green)
                          : const Chip(label: Text('Inactive'), backgroundColor: Colors.grey),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
      ],
    );
  }
}

