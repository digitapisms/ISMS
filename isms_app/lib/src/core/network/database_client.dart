import 'package:supabase_flutter/supabase_flutter.dart';

class OrderClause {
  const OrderClause(this.column, {this.ascending = true});

  final String column;
  final bool ascending;
}

abstract class DatabaseClient {
  PostgrestQueryBuilder from(String table);
  Future<Map<String, dynamic>> insertReturningSingle(
    String table,
    Map<String, dynamic> values,
  );

  Future<void> insert(String table, Map<String, dynamic> values);

  Future<void> upsert(String table, Map<String, dynamic> values);

  Future<Map<String, dynamic>?> selectMaybeSingle(
    String table, {
    String columns = '*',
    Map<String, dynamic>? filters,
    String? orFilter,
  });

  Future<List<Map<String, dynamic>>> selectList(
    String table, {
    String columns = '*',
    Map<String, dynamic>? filters,
    List<OrderClause>? orderBy,
    int? limit,
    String? orFilter,
  });

  Future<void> update(
    String table,
    Map<String, dynamic> values,
    Map<String, dynamic> filters,
  );

  Future<void> delete(String table, Map<String, dynamic> filters);

  SupabaseStorageClient get storage;
  User? get currentUser;
}

class SupabaseDatabaseClient implements DatabaseClient {
  SupabaseDatabaseClient(this._client);

  final SupabaseClient _client;

  @override
  PostgrestQueryBuilder from(String table) => _client.from(table);

  @override
  Future<Map<String, dynamic>> insertReturningSingle(
    String table,
    Map<String, dynamic> values,
  ) async {
    final response =
        await _client.from(table).insert(values).select().single();
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<void> insert(String table, Map<String, dynamic> values) async {
    await _client.from(table).insert(values);
  }

  @override
  Future<void> upsert(String table, Map<String, dynamic> values) async {
    await _client.from(table).upsert(values);
  }

  @override
  Future<Map<String, dynamic>?> selectMaybeSingle(
    String table, {
    String columns = '*',
    Map<String, dynamic>? filters,
    String? orFilter,
  }) async {
    dynamic query = _client.from(table).select(columns);
    query = _applyFilters(query, filters);
    if (orFilter != null) {
      query = query.or(orFilter);
    }
    final response = await query.maybeSingle();
    if (response == null) return null;
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<List<Map<String, dynamic>>> selectList(
    String table, {
    String columns = '*',
    Map<String, dynamic>? filters,
    List<OrderClause>? orderBy,
    int? limit,
    String? orFilter,
  }) async {
    dynamic query = _client.from(table).select(columns);
    query = _applyFilters(query, filters);
    if (orFilter != null) {
      query = query.or(orFilter);
    }
    if (orderBy != null) {
      for (final clause in orderBy) {
        query = query.order(clause.column, ascending: clause.ascending);
      }
    }
    if (limit != null) {
      query = query.limit(limit);
    }
    final response = await query;
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<void> update(
    String table,
    Map<String, dynamic> values,
    Map<String, dynamic> filters,
  ) async {
    var query = _client.from(table).update(values);
    query = _applyFilters(query, filters);
    await query;
  }

  @override
  Future<void> delete(String table, Map<String, dynamic> filters) async {
    var query = _client.from(table).delete();
    query = _applyFilters(query, filters);
    await query;
  }

  @override
  SupabaseStorageClient get storage => _client.storage;

  @override
  User? get currentUser => _client.auth.currentUser;

  dynamic _applyFilters(
    dynamic query,
    Map<String, dynamic>? filters,
  ) {
    if (filters == null) return query;
    for (final entry in filters.entries) {
      query = query.eq(entry.key, entry.value);
    }
    return query;
  }
}

