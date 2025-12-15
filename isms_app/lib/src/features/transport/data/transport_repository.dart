import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
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

class TransportRepository {
  SupabaseClient get _client => SupabaseManager.client;
  String? _schoolId;

  void setSchoolId(String? schoolId) {
    _schoolId = schoolId;
  }

  String? get schoolId => _schoolId;

  String _requireSchoolId() {
    final id = _schoolId;
    if (id == null) {
      throw Exception(
        'School context is required for this action. Please ensure you are signed in to a school tenant.',
      );
    }
    return id;
  }

  Map<String, dynamic> _withSchoolId(Map<String, dynamic> data) {
    final id = _schoolId;
    if (id == null) return data;
    return {...data, 'school_id': id};
  }

  // ============================================================
  // VEHICLES
  // ============================================================

  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    _requireSchoolId();
    final response = await _client
        .from('vehicles')
        .insert(_withSchoolId(vehicle.toMap()))
        .select()
        .single();
    return Vehicle.fromMap(response);
  }

  Future<List<Vehicle>> fetchVehicles({
    VehicleStatus? status,
    VehicleType? vehicleType,
  }) async {
    final schoolId = _requireSchoolId();
    var query = _client.from('vehicles').select().eq('school_id', schoolId);

    if (status != null) {
      query = query.eq('status', status.dbValue);
    }
    if (vehicleType != null) {
      query = query.eq('vehicle_type', vehicleType.dbValue);
    }

    final response = await query.order('vehicle_number');
    return (response as List)
        .map((e) => Vehicle.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Vehicle?> getVehicle(int id) async {
    final response = await _client
        .from('vehicles')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Vehicle.fromMap(response);
  }

  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    final response = await _client
        .from('vehicles')
        .update(vehicle.toMap())
        .eq('id', vehicle.id)
        .select()
        .single();
    return Vehicle.fromMap(response);
  }

  Future<void> deleteVehicle(int id) async {
    await _client.from('vehicles').delete().eq('id', id);
  }

  // ============================================================
  // ROUTES
  // ============================================================

  Future<Route> createRoute(Route route) async {
    _requireSchoolId();
    final response = await _client
        .from('routes')
        .insert(_withSchoolId(route.toMap()))
        .select()
        .single();
    return Route.fromMap(response);
  }

  Future<List<Route>> fetchRoutes({
    bool? isActive,
    int? vehicleId,
  }) async {
    final schoolId = _requireSchoolId();
    var query = _client.from('routes').select().eq('school_id', schoolId);

    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }
    if (vehicleId != null) {
      query = query.eq('vehicle_id', vehicleId);
    }

    final response = await query.order('route_name');
    return (response as List)
        .map((e) => Route.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Route?> getRoute(int id) async {
    final response = await _client
        .from('routes')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Route.fromMap(response);
  }

  Future<Route> updateRoute(Route route) async {
    final response = await _client
        .from('routes')
        .update(route.toMap())
        .eq('id', route.id)
        .select()
        .single();
    return Route.fromMap(response);
  }

  Future<void> deleteRoute(int id) async {
    await _client.from('routes').delete().eq('id', id);
  }

  // ============================================================
  // ROUTE STOPS
  // ============================================================

  Future<RouteStop> createRouteStop(RouteStop stop) async {
    _requireSchoolId();
    final response = await _client
        .from('route_stops')
        .insert(_withSchoolId(stop.toMap()))
        .select()
        .single();
    return RouteStop.fromMap(response);
  }

  Future<List<RouteStop>> fetchRouteStops(int routeId) async {
    final schoolId = _requireSchoolId();
    final response = await _client
        .from('route_stops')
        .select()
        .eq('school_id', schoolId)
        .eq('route_id', routeId)
        .order('stop_sequence');
    return (response as List)
        .map((e) => RouteStop.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<RouteStop> updateRouteStop(RouteStop stop) async {
    final response = await _client
        .from('route_stops')
        .update(stop.toMap())
        .eq('id', stop.id)
        .select()
        .single();
    return RouteStop.fromMap(response);
  }

  Future<void> deleteRouteStop(int id) async {
    await _client.from('route_stops').delete().eq('id', id);
  }

  // ============================================================
  // DRIVERS
  // ============================================================

  Future<Driver> createDriver(Driver driver) async {
    _requireSchoolId();
    final response = await _client
        .from('drivers')
        .insert(_withSchoolId(driver.toMap()))
        .select()
        .single();
    return Driver.fromMap(response);
  }

  Future<List<Driver>> fetchDrivers({
    StaffStatus? status,
    int? vehicleId,
  }) async {
    final schoolId = _requireSchoolId();
    var query = _client.from('drivers').select().eq('school_id', schoolId);

    if (status != null) {
      query = query.eq('status', status.dbValue);
    }
    if (vehicleId != null) {
      query = query.eq('vehicle_id', vehicleId);
    }

    final response = await query.order('full_name');
    return (response as List)
        .map((e) => Driver.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Driver?> getDriver(String id) async {
    final response = await _client
        .from('drivers')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Driver.fromMap(response);
  }

  Future<Driver> updateDriver(Driver driver) async {
    final response = await _client
        .from('drivers')
        .update(driver.toMap())
        .eq('id', driver.id)
        .select()
        .single();
    return Driver.fromMap(response);
  }

  Future<void> deleteDriver(String id) async {
    await _client.from('drivers').delete().eq('id', id);
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Future<Helper> createHelper(Helper helper) async {
    _requireSchoolId();
    final response = await _client
        .from('helpers')
        .insert(_withSchoolId(helper.toMap()))
        .select()
        .single();
    return Helper.fromMap(response);
  }

  Future<List<Helper>> fetchHelpers({
    StaffStatus? status,
    int? routeId,
    int? vehicleId,
  }) async {
    final schoolId = _requireSchoolId();
    var query = _client.from('helpers').select().eq('school_id', schoolId);

    if (status != null) {
      query = query.eq('status', status.dbValue);
    }
    if (routeId != null) {
      query = query.eq('route_id', routeId);
    }
    if (vehicleId != null) {
      query = query.eq('vehicle_id', vehicleId);
    }

    final response = await query.order('full_name');
    return (response as List)
        .map((e) => Helper.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Helper?> getHelper(String id) async {
    final response = await _client
        .from('helpers')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Helper.fromMap(response);
  }

  Future<Helper> updateHelper(Helper helper) async {
    final response = await _client
        .from('helpers')
        .update(helper.toMap())
        .eq('id', helper.id)
        .select()
        .single();
    return Helper.fromMap(response);
  }

  Future<void> deleteHelper(String id) async {
    await _client.from('helpers').delete().eq('id', id);
  }

  // ============================================================
  // TRANSPORT ASSIGNMENTS
  // ============================================================

  Future<TransportAssignment> createAssignment(
    TransportAssignment assignment,
  ) async {
    _requireSchoolId();
    final response = await _client
        .from('transport_assignments')
        .insert(_withSchoolId(assignment.toMap()))
        .select()
        .single();
    return TransportAssignment.fromMap(response);
  }

  Future<List<TransportAssignment>> fetchAssignments({
    String? studentId,
    int? routeId,
    bool? isActive,
  }) async {
    final schoolId = _requireSchoolId();
    var query = _client
        .from('transport_assignments')
        .select()
        .eq('school_id', schoolId);

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (routeId != null) {
      query = query.eq('route_id', routeId);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query.order('assignment_date', ascending: false);
    return (response as List)
        .map((e) => TransportAssignment.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<TransportAssignment> updateAssignment(
    TransportAssignment assignment,
  ) async {
    final response = await _client
        .from('transport_assignments')
        .update(assignment.toMap())
        .eq('id', assignment.id)
        .select()
        .single();
    return TransportAssignment.fromMap(response);
  }

  Future<void> deleteAssignment(String id) async {
    await _client.from('transport_assignments').delete().eq('id', id);
  }

  // ============================================================
  // TRANSPORT ATTENDANCE
  // ============================================================

  Future<TransportAttendance> markAttendance(
    TransportAttendance attendance,
  ) async {
    _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final attendanceData = {
      ..._withSchoolId(attendance.toMap()),
      'marked_by': userId,
    };

    final response = await _client
        .from('transport_attendance')
        .upsert(
          attendanceData,
          onConflict: 'student_id,route_id,attendance_date,trip_type',
        )
        .select()
        .single();
    return TransportAttendance.fromMap(response);
  }

  Future<List<TransportAttendance>> fetchAttendance({
    String? studentId,
    int? routeId,
    DateTime? date,
    TripType? tripType,
  }) async {
    final schoolId = _requireSchoolId();
    var query = _client
        .from('transport_attendance')
        .select()
        .eq('school_id', schoolId);

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (routeId != null) {
      query = query.eq('route_id', routeId);
    }
    if (date != null) {
      query = query.eq(
        'attendance_date',
        date.toIso8601String().split('T')[0],
      );
    }
    if (tripType != null) {
      query = query.eq('trip_type', tripType.dbValue);
    }

    final response = await query.order('attendance_date', ascending: false);
    return (response as List)
        .map((e) => TransportAttendance.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // TRANSPORT FEES
  // ============================================================

  Future<TransportFee> createTransportFee(TransportFee fee) async {
    _requireSchoolId();
    final response = await _client
        .from('transport_fees')
        .insert(_withSchoolId(fee.toMap()))
        .select()
        .single();
    return TransportFee.fromMap(response);
  }

  Future<List<TransportFee>> fetchTransportFees({
    String? studentId,
    int? routeId,
    FeeStatus? status,
    DateTime? feeMonth,
  }) async {
    final schoolId = _requireSchoolId();
    var query = _client.from('transport_fees').select().eq('school_id', schoolId);

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (routeId != null) {
      query = query.eq('route_id', routeId);
    }
    if (status != null) {
      query = query.eq('status', status.dbValue);
    }
    if (feeMonth != null) {
      query = query.eq('fee_month', feeMonth.toIso8601String().split('T')[0]);
    }

    final response = await query.order('fee_month', ascending: false);
    return (response as List)
        .map((e) => TransportFee.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<TransportFee> payTransportFee({
    required String feeId,
    required String paymentMethod,
    String? paymentReference,
    String? challanNumber,
    String? voucherNumber,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('transport_fees')
        .update({
          'status': 'paid',
          'paid_date': DateTime.now().toIso8601String().split('T')[0],
          'payment_method': paymentMethod,
          'payment_reference': paymentReference,
          'challan_number': challanNumber,
          'voucher_number': voucherNumber,
        })
        .eq('id', feeId)
        .select()
        .single();
    return TransportFee.fromMap(response);
  }

  Future<TransportFee> waiveTransportFee({
    required String feeId,
    required String reason,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('transport_fees')
        .update({
          'status': 'waived',
          'waived_at': DateTime.now().toIso8601String(),
          'waived_by': userId,
          'waiver_reason': reason,
        })
        .eq('id', feeId)
        .select()
        .single();
    return TransportFee.fromMap(response);
  }

  // ============================================================
  // VEHICLE MAINTENANCE
  // ============================================================

  Future<VehicleMaintenance> createMaintenance(
    VehicleMaintenance maintenance,
  ) async {
    _requireSchoolId();
    final userId = _client.auth.currentUser?.id;
    final maintenanceData = {
      ..._withSchoolId(maintenance.toMap()),
      if (userId != null) 'performed_by': userId,
    };

    final response = await _client
        .from('vehicle_maintenance')
        .insert(maintenanceData)
        .select()
        .single();
    return VehicleMaintenance.fromMap(response);
  }

  Future<List<VehicleMaintenance>> fetchMaintenance({
    int? vehicleId,
    MaintenanceType? maintenanceType,
  }) async {
    final schoolId = _requireSchoolId();
    var query = _client
        .from('vehicle_maintenance')
        .select()
        .eq('school_id', schoolId);

    if (vehicleId != null) {
      query = query.eq('vehicle_id', vehicleId);
    }
    if (maintenanceType != null) {
      query = query.eq('maintenance_type', maintenanceType.dbValue);
    }

    final response = await query.order('maintenance_date', ascending: false);
    return (response as List)
        .map((e) => VehicleMaintenance.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<VehicleMaintenance> updateMaintenance(
    VehicleMaintenance maintenance,
  ) async {
    final response = await _client
        .from('vehicle_maintenance')
        .update(maintenance.toMap())
        .eq('id', maintenance.id)
        .select()
        .single();
    return VehicleMaintenance.fromMap(response);
  }

  Future<void> deleteMaintenance(String id) async {
    await _client.from('vehicle_maintenance').delete().eq('id', id);
  }
}

