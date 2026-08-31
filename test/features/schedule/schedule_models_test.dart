import 'package:caloris/features/schedule/domain/schedule_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ScheduleGapAdvisor finds a practical activity gap', () {
    const entries = [
      ScheduleEntry(
        id: 'morning',
        userId: 'user',
        dayOfWeek: 1,
        activityName: 'Kerja',
        startTime: LocalTime(hour: 8, minute: 0),
        endTime: LocalTime(hour: 17, minute: 0),
        category: ScheduleCategory.work,
        busynessLevel: 3,
      ),
      ScheduleEntry(
        id: 'evening',
        userId: 'user',
        dayOfWeek: 1,
        activityName: 'Belajar',
        startTime: LocalTime(hour: 18, minute: 0),
        endTime: LocalTime(hour: 20, minute: 0),
        category: ScheduleCategory.study,
        busynessLevel: 2,
      ),
    ];

    final suggestion = ScheduleGapAdvisor.recommend(entries, dayOfWeek: 1);

    expect(suggestion, contains('17:00–18:00'));
    expect(suggestion, contains('jalan kaki'));
  });

  test('ReminderSetting rejects missing or invalid repeat days', () {
    expect(
      () => const ReminderSetting(
        id: '',
        userId: '',
        type: ReminderType.water,
        time: LocalTime(hour: 9, minute: 0),
        enabled: true,
        repeatDays: [],
      ).validate(),
      throwsA(isA<ArgumentError>()),
    );
  });
}
