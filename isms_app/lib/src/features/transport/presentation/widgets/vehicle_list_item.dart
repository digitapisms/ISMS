import 'package:flutter/material.dart';

import '../../domain/vehicle.dart';
import '../../domain/transport_type.dart';

class VehicleListItem extends StatelessWidget {
  const VehicleListItem({
    super.key,
    required this.vehicle,
    this.onTap,
  });

  final Vehicle vehicle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasExpiringDocs = vehicle.isFitnessExpiringSoon ||
        vehicle.isInsuranceExpiringSoon ||
        vehicle.isFitnessExpired ||
        vehicle.isInsuranceExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: hasExpiringDocs ? Colors.orange.withOpacity(0.05) : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.vehicleNumber,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (vehicle.registrationNumber != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Reg: ${vehicle.registrationNumber}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(vehicle.vehicleType.displayName),
                    backgroundColor:
                        _getTypeColor(vehicle.vehicleType).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _getTypeColor(vehicle.vehicleType),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(vehicle.status.displayName),
                    backgroundColor:
                        _getStatusColor(vehicle.status).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _getStatusColor(vehicle.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Capacity: ${vehicle.capacity}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (vehicle.make != null || vehicle.model != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${vehicle.make ?? ''} ${vehicle.model ?? ''}'.trim(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
              if (hasExpiringDocs) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.warning, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _getExpiryWarning(vehicle),
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(VehicleType type) {
    switch (type) {
      case VehicleType.bus:
        return Colors.blue;
      case VehicleType.van:
        return Colors.green;
      case VehicleType.car:
        return Colors.purple;
      case VehicleType.coaster:
        return Colors.orange;
    }
  }

  Color _getStatusColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.active:
        return Colors.green;
      case VehicleStatus.maintenance:
        return Colors.orange;
      case VehicleStatus.retired:
        return Colors.grey;
    }
  }

  String _getExpiryWarning(Vehicle vehicle) {
    final warnings = <String>[];
    if (vehicle.isFitnessExpired) {
      warnings.add('Fitness Certificate EXPIRED');
    } else if (vehicle.isFitnessExpiringSoon) {
      warnings.add('Fitness Certificate expiring soon');
    }
    if (vehicle.isInsuranceExpired) {
      warnings.add('Insurance EXPIRED');
    } else if (vehicle.isInsuranceExpiringSoon) {
      warnings.add('Insurance expiring soon');
    }
    return warnings.join(' • ');
  }
}

