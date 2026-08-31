import 'package:caloris/features/schedule/domain/schedule_models.dart';

abstract interface class ScheduleRepository {
  Future<List<ScheduleEntry>> listSchedules();
  Future<ScheduleEntry> saveSchedule(ScheduleEntry entry);
  Future<void> deleteSchedule(String id);
  Future<List<ReminderSetting>> listReminders();
  Future<ReminderSetting> saveReminder(ReminderSetting reminder);
  Future<void> deleteReminder(String id);
}
