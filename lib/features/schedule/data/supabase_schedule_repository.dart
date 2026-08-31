import 'package:caloris/core/config/app_environment.dart';
import 'package:caloris/core/errors/app_failure.dart';
import 'package:caloris/features/schedule/domain/schedule_models.dart';
import 'package:caloris/features/schedule/domain/schedule_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (!environment.isConfigured) return const UnavailableScheduleRepository();
  return SupabaseScheduleRepository(Supabase.instance.client);
});

class SupabaseScheduleRepository implements ScheduleRepository {
  const SupabaseScheduleRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ScheduleEntry>> listSchedules() async {
    try {
      final rows = await _client
          .from('schedules')
          .select()
          .order('day_of_week')
          .order('start_time');
      return rows.map(ScheduleEntry.fromJson).toList(growable: false);
    } on PostgrestException catch (error) {
      throw DataFailure(_message(error));
    }
  }

  @override
  Future<ScheduleEntry> saveSchedule(ScheduleEntry entry) async {
    entry.validate();
    final ownerId = _requireUserId();
    try {
      final query = entry.id.isEmpty
          ? _client.from('schedules').insert(entry.toWriteJson(ownerId))
          : _client
                .from('schedules')
                .update(entry.toWriteJson(ownerId))
                .eq('id', entry.id);
      final data = await query.select().single();
      return ScheduleEntry.fromJson(data);
    } on PostgrestException catch (error) {
      throw DataFailure(_message(error));
    }
  }

  @override
  Future<void> deleteSchedule(String id) async {
    try {
      await _client.from('schedules').delete().eq('id', id);
    } on PostgrestException catch (error) {
      throw DataFailure(_message(error));
    }
  }

  @override
  Future<List<ReminderSetting>> listReminders() async {
    try {
      final rows = await _client
          .from('reminders')
          .select()
          .order('reminder_time');
      return rows.map(ReminderSetting.fromJson).toList(growable: false);
    } on PostgrestException catch (error) {
      throw DataFailure(_message(error));
    }
  }

  @override
  Future<ReminderSetting> saveReminder(ReminderSetting reminder) async {
    reminder.validate();
    final ownerId = _requireUserId();
    try {
      final query = reminder.id.isEmpty
          ? _client.from('reminders').insert(reminder.toWriteJson(ownerId))
          : _client
                .from('reminders')
                .update(reminder.toWriteJson(ownerId))
                .eq('id', reminder.id);
      final data = await query.select().single();
      return ReminderSetting.fromJson(data);
    } on PostgrestException catch (error) {
      throw DataFailure(_message(error));
    }
  }

  @override
  Future<void> deleteReminder(String id) async {
    try {
      await _client.from('reminders').delete().eq('id', id);
    } on PostgrestException catch (error) {
      throw DataFailure(_message(error));
    }
  }

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AuthenticationFailure(
        'Sesi telah berakhir. Silakan masuk lagi.',
      );
    }
    return id;
  }

  String _message(PostgrestException error) => error.code == '42501'
      ? 'Kamu tidak memiliki izin untuk jadwal ini.'
      : 'Jadwal belum dapat diproses. Coba lagi.';
}

class UnavailableScheduleRepository implements ScheduleRepository {
  const UnavailableScheduleRepository();

  Future<T> _unavailable<T>() => Future<T>.error(const ConfigurationFailure());

  @override
  Future<void> deleteReminder(String id) => _unavailable();

  @override
  Future<void> deleteSchedule(String id) => _unavailable();

  @override
  Future<List<ReminderSetting>> listReminders() => _unavailable();

  @override
  Future<List<ScheduleEntry>> listSchedules() => _unavailable();

  @override
  Future<ReminderSetting> saveReminder(ReminderSetting reminder) =>
      _unavailable();

  @override
  Future<ScheduleEntry> saveSchedule(ScheduleEntry entry) => _unavailable();
}
