import 'dart:convert';

import 'package:caloris/core/offline/offline_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

final offlineStoreProvider = Provider<OfflineStore>(
  (ref) => SqliteOfflineStore(),
);

class SqliteOfflineStore implements OfflineStore {
  Database? _database;

  Future<Database> get _db async => _database ??= await _open();

  Future<Database> _open() async {
    final root = await getDatabasesPath();
    return openDatabase(
      '$root/caloris_offline.db',
      version: 1,
      onCreate: (database, _) async {
        await database.execute('''
          create table cache_entries (
            owner_id text not null,
            cache_key text not null,
            payload text not null,
            updated_at integer not null,
            primary key (owner_id, cache_key)
          )
        ''');
        await database.execute('''
          create table mutation_outbox (
            id text primary key,
            owner_id text not null,
            entity text not null,
            operation text not null,
            payload text not null,
            created_at integer not null,
            attempts integer not null default 0
          )
        ''');
        await database.execute(
          'create index outbox_owner_entity_idx '
          'on mutation_outbox (owner_id, entity, created_at)',
        );
      },
    );
  }

  @override
  Future<void> writeCache({
    required String ownerId,
    required String cacheKey,
    required String payload,
  }) async {
    await (await _db).insert('cache_entries', {
      'owner_id': ownerId,
      'cache_key': cacheKey,
      'payload': payload,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 90))
        .millisecondsSinceEpoch;
    await (await _db).delete(
      'cache_entries',
      where: 'cache_key like ? and updated_at < ?',
      whereArgs: ['food-day:%', cutoff],
    );
  }

  @override
  Future<String?> readCache({
    required String ownerId,
    required String cacheKey,
  }) async {
    final rows = await (await _db).query(
      'cache_entries',
      columns: ['payload'],
      where: 'owner_id = ? and cache_key = ?',
      whereArgs: [ownerId, cacheKey],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single['payload']! as String;
  }

  @override
  Future<void> removeRecordFromCaches({
    required String ownerId,
    required String cachePrefix,
    required String recordId,
  }) async {
    final database = await _db;
    final rows = await database.query(
      'cache_entries',
      where: 'owner_id = ? and cache_key like ?',
      whereArgs: [ownerId, '$cachePrefix%'],
    );
    for (final row in rows) {
      final decoded = jsonDecode(row['payload']! as String);
      if (decoded is! List) continue;
      decoded.removeWhere((item) => item is Map && item['id'] == recordId);
      await writeCache(
        ownerId: ownerId,
        cacheKey: row['cache_key']! as String,
        payload: jsonEncode(decoded),
      );
    }
  }

  @override
  Future<void> enqueue(OutboxMutation mutation) async {
    await (await _db).insert('mutation_outbox', {
      'id': mutation.id,
      'owner_id': mutation.ownerId,
      'entity': mutation.entity,
      'operation': mutation.operation,
      'payload': jsonEncode(mutation.payload),
      'created_at': mutation.createdAt.millisecondsSinceEpoch,
      'attempts': mutation.attempts,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<OutboxMutation>> pending({
    required String ownerId,
    required String entity,
    int limit = 20,
  }) async {
    final rows = await (await _db).query(
      'mutation_outbox',
      where: 'owner_id = ? and entity = ?',
      whereArgs: [ownerId, entity],
      orderBy: 'created_at',
      limit: limit.clamp(1, 100),
    );
    return rows
        .map(
          (row) => OutboxMutation(
            id: row['id']! as String,
            ownerId: row['owner_id']! as String,
            entity: row['entity']! as String,
            operation: row['operation']! as String,
            payload: Map<String, Object?>.from(
              jsonDecode(row['payload']! as String) as Map,
            ),
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              row['created_at']! as int,
            ),
            attempts: row['attempts']! as int,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> removeMutation(String id) async {
    await (await _db).delete(
      'mutation_outbox',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> incrementAttempt(String id) async {
    await (await _db).rawUpdate(
      'update mutation_outbox set attempts = attempts + 1 where id = ?',
      [id],
    );
  }

  @override
  Future<void> clearOwner(String ownerId) async {
    final database = await _db;
    await database.transaction((transaction) async {
      await transaction.delete(
        'cache_entries',
        where: 'owner_id = ?',
        whereArgs: [ownerId],
      );
      await transaction.delete(
        'mutation_outbox',
        where: 'owner_id = ?',
        whereArgs: [ownerId],
      );
    });
  }
}
