class OutboxMutation {
  const OutboxMutation({
    required this.id,
    required this.ownerId,
    required this.entity,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
  });

  final String id;
  final String ownerId;
  final String entity;
  final String operation;
  final Map<String, Object?> payload;
  final DateTime createdAt;
  final int attempts;

  OutboxMutation copyWith({int? attempts}) => OutboxMutation(
    id: id,
    ownerId: ownerId,
    entity: entity,
    operation: operation,
    payload: payload,
    createdAt: createdAt,
    attempts: attempts ?? this.attempts,
  );
}

abstract interface class OfflineStore {
  Future<void> writeCache({
    required String ownerId,
    required String cacheKey,
    required String payload,
  });

  Future<String?> readCache({
    required String ownerId,
    required String cacheKey,
  });

  Future<void> removeRecordFromCaches({
    required String ownerId,
    required String cachePrefix,
    required String recordId,
  });

  Future<void> enqueue(OutboxMutation mutation);

  Future<List<OutboxMutation>> pending({
    required String ownerId,
    required String entity,
    int limit = 20,
  });

  Future<void> removeMutation(String id);
  Future<void> incrementAttempt(String id);
  Future<void> clearOwner(String ownerId);
}
