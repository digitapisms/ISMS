import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(transportRepositoryProvider);
  return repo.fetchVehicles();
});

final activeVehiclesProvider = FutureProvider<List<Vehicle>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(transportRepositoryProvider);
  return repo.fetchVehicles(status: VehicleStatus.active);
});

final vehicleProvider =
    FutureProvider.family<Vehicle?, int>((ref, vehicleId) async {
  final repo = ref.read(transportRepositoryProvider);
  return repo.getVehicle(vehicleId);
});

// ============================================================
// ROUTES
// ============================================================

final routesProvider = FutureProvider<List<Route>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(transportRepositoryProvider);
  return repo.fetchRoutes();
});

final activeRoutesProvider = FutureProvider<List<Route>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(transportRepositoryProvider);
  return repo.fetchRoutes(isActive: true);
});

final routeProvider = FutureProvider.family<Route?, int>((ref, routeId) async {
  final repo = ref.read(transportRepositoryProvider);
  return repo.getRoute(routeId);
});

final routesByVehicleProvider =
    FutureProvider.family<List<Route>, int>((ref, vehicleId) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(transportRepositoryProvider);
  return repo.fetchRoutes(vehicleId: vehicleId);
});

// ============================================================
// ROUTE STOPS
// ============================================================

final routeStopsProvider =
    FutureProvider.family<List<RouteStop>, int>((ref, routeId) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(transportRepositoryProvider);
  return repo.fetchRouteStops(routeId);
});

// ============================================================
// DRIVERS
// ============================================================

final driversProvider = FutureProvider<List<Driver>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(transportRepositoryProvider);
  return repo.fetchDrivers();
});

final activeDriversProvider = FutureProvider<List<Driver>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(transportRepositoryProvider);
  return repo.fetchDrivers(status: StaffStatus.active);
});

final driverProvider =
    FutureProvider.family<Driver?, String>((ref, driverId) async {
  final repo = ref.read(transportRepositoryProvider);
  return repo.getDriver(driverId);
});

// ============================================================
// HELPERS
// ============================================================

final helpersProvider = FutureProvider<List<Helper>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(transportRepositoryProvider);
  return repo.fetchHelpers();
});

final activeHelpersProvider = FutureProvider<List<Helper>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(transportRepositoryProvider);
  return repo.fetchHelpers(status: StaffStatus.active);
});

final helperProvider =
    FutureProvider.family<Helper?, String>((ref, helperId) async {
  final repo = ref.read(transportRepositoryProvider);
  return repo.getHelper(helperId);
});

// ============================================================
// TRANSPORT ASSIGNMENTS
// ============================================================

final transportAssignmentsProvider =
    FutureProvider<List<TransportAssignment>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(transportRepositoryProvider);
  return repo.fetchAssignments();
});

final assignmentsByStudentProvider =
    FutureProvider.family<List<TransportAssignment>, String>(
  (ref, studentId) async {
    final school = ref.watch(currentSchoolProvider);
    if (school == null) return [];
    final repo = ref.read(transportRepositoryProvider);
    return repo.fetchAssignments(studentId: studentId, isActive: true);
  },
);

final assignmentsByRouteProvider =
    FutureProvider.family<List<TransportAssignment>, int>(
  (ref, routeId) async {
    final school = ref.watch(currentSchoolProvider);
    if (school == null) return [];
    final repo = ref.read(transportRepositoryProvider);
    return repo.fetchAssignments(routeId: routeId, isActive: true);
  },
);

// ============================================================
// TRANSPORT ATTENDANCE
// ============================================================

final transportAttendanceProvider =
    FutureProvider.family<List<TransportAttendance>, DateTime>(
  (ref, date) async {
    final school = ref.watch(currentSchoolProvider);
    if (school == null) return [];
    final repo = ref.read(transportRepositoryProvider);
    return repo.fetchAttendance(date: date);
  },
);

final attendanceByStudentProvider =
    FutureProvider.family<List<TransportAttendance>, String>(
  (ref, studentId) async {
    final school = ref.watch(currentSchoolProvider);
    if (school == null) return [];
    final repo = ref.read(transportRepositoryProvider);
    return repo.fetchAttendance(studentId: studentId);
  },
);

final attendanceByRouteProvider =
    FutureProvider.family<List<TransportAttendance>, int>(
  (ref, routeId) async {
    final school = ref.watch(currentSchoolProvider);
    if (school == null) return [];
    final repo = ref.read(transportRepositoryProvider);
    return repo.fetchAttendance(routeId: routeId);
  },
);

// ============================================================
// TRANSPORT FEES
// ============================================================

final transportFeesProvider = FutureProvider<List<TransportFee>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(transportRepositoryProvider);
  return repo.fetchTransportFees();
});

final feesByStudentProvider =
    FutureProvider.family<List<TransportFee>, String>((ref, studentId) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(transportRepositoryProvider);
  return repo.fetchTransportFees(studentId: studentId);
});

final pendingFeesProvider = FutureProvider<List<TransportFee>>((ref) async {
  final school = ref.watch(currentSchoolProvider);
  if (school == null) return [];
  final repo = ref.read(transportRepositoryProvider);
  return repo.fetchTransportFees(status: FeeStatus.pending);
});

// ============================================================
// VEHICLE MAINTENANCE
// ============================================================

final vehicleMaintenanceProvider =
    FutureProvider.family<List<VehicleMaintenance>, int>(
  (ref, vehicleId) async {
    final school = ref.watch(currentSchoolProvider);
    if (school == null) return [];
    final repo = ref.read(transportRepositoryProvider);
    return repo.fetchMaintenance(vehicleId: vehicleId);
  },
);

