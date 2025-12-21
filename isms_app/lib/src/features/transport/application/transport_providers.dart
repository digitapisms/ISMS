import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/errors/provider_helpers.dart';
import '../../school_registration/application/school_providers.dart';
import '../data/transport_repository.dart';
import '../domain/driver.dart';
import '../domain/helper.dart';
import '../domain/route.dart';
import '../domain/route_stop.dart';
import '../domain/transport_assignment.dart';
import '../domain/transport_attendance.dart';
import '../domain/transport_fee.dart';
import '../domain/transport_type.dart';
import '../domain/vehicle.dart';
import '../domain/vehicle_maintenance.dart';

final transportRepositoryProvider = Provider<TransportRepository>((ref) {
  final repo = TransportRepository();
  final school = ref.watch(currentSchoolProvider);
  if (school != null) {
    repo.setSchoolId(school.id);
  }
  return repo;
});

// ============================================================
// VEHICLES
// ============================================================

final vehiclesProvider = FutureProvider<List<Vehicle>>((ref) async {
  return safeProviderOperation<List<Vehicle>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(transportRepositoryProvider);
      return await repo.fetchVehicles().timeout(const Duration(seconds: 10));
    },
    onError: () => <Vehicle>[],
    context: 'VehiclesProvider',
  );
});

final activeVehiclesProvider = FutureProvider<List<Vehicle>>((ref) async {
  return safeProviderOperation<List<Vehicle>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(transportRepositoryProvider);
      return await repo
          .fetchVehicles(status: VehicleStatus.active)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <Vehicle>[],
    context: 'ActiveVehiclesProvider',
  );
});

final vehicleProvider = FutureProvider.family<Vehicle?, int>((
  ref,
  vehicleId,
) async {
  final correlationId = ErrorHandler.generateCorrelationId();

  try {
    final repo = ref.read(transportRepositoryProvider);
    return await repo
        .getVehicle(vehicleId)
        .timeout(const Duration(seconds: 10), onTimeout: () => null);
  } catch (e) {
    final error = ErrorHandler.handleException(
      e,
      correlationId: correlationId,
      context: 'VehicleProvider',
    );
    ErrorHandler.logError(error);
    return null;
  }
});

// ============================================================
// ROUTES
// ============================================================

final routesProvider = FutureProvider<List<Route>>((ref) async {
  return safeProviderOperation<List<Route>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(transportRepositoryProvider);
      return await repo.fetchRoutes().timeout(const Duration(seconds: 10));
    },
    onError: () => <Route>[],
    context: 'RoutesProvider',
  );
});

final activeRoutesProvider = FutureProvider<List<Route>>((ref) async {
  return safeProviderOperation<List<Route>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(transportRepositoryProvider);
      return await repo
          .fetchRoutes(isActive: true)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <Route>[],
    context: 'ActiveRoutesProvider',
  );
});

final routeProvider = FutureProvider.family<Route?, int>((ref, routeId) async {
  final correlationId = ErrorHandler.generateCorrelationId();

  try {
    final repo = ref.read(transportRepositoryProvider);
    return await repo
        .getRoute(routeId)
        .timeout(const Duration(seconds: 10), onTimeout: () => null);
  } catch (e) {
    final error = ErrorHandler.handleException(
      e,
      correlationId: correlationId,
      context: 'RouteProvider',
    );
    ErrorHandler.logError(error);
    return null;
  }
});

final routesByVehicleProvider = FutureProvider.family<List<Route>, int>((
  ref,
  vehicleId,
) async {
  return safeProviderOperation<List<Route>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(transportRepositoryProvider);
      return await repo
          .fetchRoutes(vehicleId: vehicleId)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <Route>[],
    context: 'RoutesByVehicleProvider',
  );
});

// ============================================================
// ROUTE STOPS
// ============================================================

final routeStopsProvider = FutureProvider.family<List<RouteStop>, int>((
  ref,
  routeId,
) async {
  return safeProviderOperation<List<RouteStop>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(transportRepositoryProvider);
      return await repo
          .fetchRouteStops(routeId)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <RouteStop>[],
    context: 'RouteStopsProvider',
  );
});

// ============================================================
// DRIVERS
// ============================================================

final driversProvider = FutureProvider<List<Driver>>((ref) async {
  return safeProviderOperation<List<Driver>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(transportRepositoryProvider);
      return await repo.fetchDrivers().timeout(const Duration(seconds: 10));
    },
    onError: () => <Driver>[],
    context: 'DriversProvider',
  );
});

final activeDriversProvider = FutureProvider<List<Driver>>((ref) async {
  return safeProviderOperation<List<Driver>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(transportRepositoryProvider);
      return await repo
          .fetchDrivers(status: StaffStatus.active)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <Driver>[],
    context: 'ActiveDriversProvider',
  );
});

final driverProvider = FutureProvider.family<Driver?, String>((
  ref,
  driverId,
) async {
  final correlationId = ErrorHandler.generateCorrelationId();

  try {
    final repo = ref.read(transportRepositoryProvider);
    return await repo
        .getDriver(driverId)
        .timeout(const Duration(seconds: 10), onTimeout: () => null);
  } catch (e) {
    final error = ErrorHandler.handleException(
      e,
      correlationId: correlationId,
      context: 'DriverProvider',
    );
    ErrorHandler.logError(error);
    return null;
  }
});

// ============================================================
// HELPERS
// ============================================================

final helpersProvider = FutureProvider<List<Helper>>((ref) async {
  return safeProviderOperation<List<Helper>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(transportRepositoryProvider);
      return await repo.fetchHelpers().timeout(const Duration(seconds: 10));
    },
    onError: () => <Helper>[],
    context: 'HelpersProvider',
  );
});

final activeHelpersProvider = FutureProvider<List<Helper>>((ref) async {
  return safeProviderOperation<List<Helper>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(transportRepositoryProvider);
      return await repo
          .fetchHelpers(status: StaffStatus.active)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <Helper>[],
    context: 'ActiveHelpersProvider',
  );
});

final helperProvider = FutureProvider.family<Helper?, String>((
  ref,
  helperId,
) async {
  final correlationId = ErrorHandler.generateCorrelationId();

  try {
    final repo = ref.read(transportRepositoryProvider);
    return await repo
        .getHelper(helperId)
        .timeout(const Duration(seconds: 10), onTimeout: () => null);
  } catch (e) {
    final error = ErrorHandler.handleException(
      e,
      correlationId: correlationId,
      context: 'HelperProvider',
    );
    ErrorHandler.logError(error);
    return null;
  }
});

// ============================================================
// TRANSPORT ASSIGNMENTS
// ============================================================

final transportAssignmentsProvider = FutureProvider<List<TransportAssignment>>((
  ref,
) async {
  return safeProviderOperation<List<TransportAssignment>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(transportRepositoryProvider);
      return await repo.fetchAssignments().timeout(const Duration(seconds: 10));
    },
    onError: () => <TransportAssignment>[],
    context: 'TransportAssignmentsProvider',
  );
});

final assignmentsByStudentProvider =
    FutureProvider.family<List<TransportAssignment>, String>((
      ref,
      studentId,
    ) async {
      return safeProviderOperation<List<TransportAssignment>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(transportRepositoryProvider);
          return await repo
              .fetchAssignments(studentId: studentId, isActive: true)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <TransportAssignment>[],
        context: 'AssignmentsByStudentProvider',
      );
    });

final assignmentsByRouteProvider =
    FutureProvider.family<List<TransportAssignment>, int>((ref, routeId) async {
      return safeProviderOperation<List<TransportAssignment>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(transportRepositoryProvider);
          return await repo
              .fetchAssignments(routeId: routeId, isActive: true)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <TransportAssignment>[],
        context: 'AssignmentsByRouteProvider',
      );
    });

// ============================================================
// TRANSPORT ATTENDANCE
// ============================================================

final transportAttendanceProvider =
    FutureProvider.family<List<TransportAttendance>, DateTime>((
      ref,
      date,
    ) async {
      return safeProviderOperation<List<TransportAttendance>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(transportRepositoryProvider);
          return await repo
              .fetchAttendance(date: date)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <TransportAttendance>[],
        context: 'TransportAttendanceProvider',
      );
    });

final attendanceByStudentProvider =
    FutureProvider.family<List<TransportAttendance>, String>((
      ref,
      studentId,
    ) async {
      return safeProviderOperation<List<TransportAttendance>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(transportRepositoryProvider);
          return await repo
              .fetchAttendance(studentId: studentId)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <TransportAttendance>[],
        context: 'AttendanceByStudentProvider',
      );
    });

final attendanceByRouteProvider =
    FutureProvider.family<List<TransportAttendance>, int>((ref, routeId) async {
      return safeProviderOperation<List<TransportAttendance>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(transportRepositoryProvider);
          return await repo
              .fetchAttendance(routeId: routeId)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <TransportAttendance>[],
        context: 'AttendanceByRouteProvider',
      );
    });

// ============================================================
// TRANSPORT FEES
// ============================================================

final transportFeesProvider = FutureProvider<List<TransportFee>>((ref) async {
  return safeProviderOperation<List<TransportFee>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(transportRepositoryProvider);
      return await repo.fetchTransportFees().timeout(
        const Duration(seconds: 10),
      );
    },
    onError: () => <TransportFee>[],
    context: 'TransportFeesProvider',
  );
});

final feesByStudentProvider = FutureProvider.family<List<TransportFee>, String>(
  (ref, studentId) async {
    return safeProviderOperation<List<TransportFee>>(
      ref: ref,
      operation: (schoolId) async {
        final repo = ref.read(transportRepositoryProvider);
        return await repo
            .fetchTransportFees(studentId: studentId)
            .timeout(const Duration(seconds: 10));
      },
      onError: () => <TransportFee>[],
      context: 'FeesByStudentProvider',
    );
  },
);

final pendingFeesProvider = FutureProvider<List<TransportFee>>((ref) async {
  return safeProviderOperation<List<TransportFee>>(
    ref: ref,
    operation: (schoolId) async {
      final repo = ref.read(transportRepositoryProvider);
      return await repo
          .fetchTransportFees(status: FeeStatus.pending)
          .timeout(const Duration(seconds: 10));
    },
    onError: () => <TransportFee>[],
    context: 'PendingFeesProvider',
  );
});

// ============================================================
// VEHICLE MAINTENANCE
// ============================================================

final vehicleMaintenanceProvider =
    FutureProvider.family<List<VehicleMaintenance>, int>((
      ref,
      vehicleId,
    ) async {
      return safeProviderOperation<List<VehicleMaintenance>>(
        ref: ref,
        operation: (schoolId) async {
          final repo = ref.read(transportRepositoryProvider);
          return await repo
              .fetchMaintenance(vehicleId: vehicleId)
              .timeout(const Duration(seconds: 10));
        },
        onError: () => <VehicleMaintenance>[],
        context: 'VehicleMaintenanceProvider',
      );
    });
