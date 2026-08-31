import 'package:caloris/features/schedule/data/supabase_schedule_repository.dart';
import 'package:caloris/features/schedule/domain/schedule_models.dart';
import 'package:caloris/features/schedule/services/local_reminder_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final schedulesProvider = FutureProvider<List<ScheduleEntry>>(
  (ref) => ref.watch(scheduleRepositoryProvider).listSchedules(),
);

final remindersProvider = FutureProvider<List<ReminderSetting>>(
  (ref) => ref.watch(scheduleRepositoryProvider).listReminders(),
);

class ScheduleActions {
  const ScheduleActions(this.ref);

  final Ref ref;

  Future<void> saveSchedule(ScheduleEntry entry) async {
    await ref.read(scheduleRepositoryProvider).saveSchedule(entry);
    ref.invalidate(schedulesProvider);
  }

  Future<void> deleteSchedule(String id) async {
    await ref.read(scheduleRepositoryProvider).deleteSchedule(id);
    ref.invalidate(schedulesProvider);
  }

  Future<bool> saveReminder(ReminderSetting reminder) async {
    final saved = await ref
        .read(scheduleRepositoryProvider)
        .saveReminder(reminder);
    ref.invalidate(remindersProvider);
    try {
      final permission = await ref
          .read(reminderSchedulerProvider)
          .requestPermission();
      if (!permission) return false;
      await ref.read(reminderSchedulerProvider).sync(saved);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteReminder(String id) async {
    await ref.read(scheduleRepositoryProvider).deleteReminder(id);
    ref.invalidate(remindersProvider);
    try {
      await ref.read(reminderSchedulerProvider).cancel(id);
    } catch (_) {
      // The cloud setting is still deleted when local notification APIs fail.
    }
  }
}

final scheduleActionsProvider = Provider(ScheduleActions.new);
