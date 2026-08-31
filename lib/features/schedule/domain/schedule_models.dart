enum ScheduleCategory {
  study('study', 'Kuliah'),
  work('work', 'Kerja'),
  travel('travel', 'Perjalanan'),
  rest('rest', 'Istirahat'),
  exercise('exercise', 'Olahraga'),
  other('other', 'Lainnya');

  const ScheduleCategory(this.databaseValue, this.label);
  final String databaseValue;
  final String label;

  static ScheduleCategory fromDatabase(String value) => values.firstWhere(
    (item) => item.databaseValue == value,
    orElse: () => ScheduleCategory.other,
  );
}

enum ReminderType {
  breakfast('breakfast', 'Sarapan'),
  lunch('lunch', 'Makan siang'),
  dinner('dinner', 'Makan malam'),
  water('water', 'Minum air'),
  walk('walk', 'Jalan kaki'),
  activity('activity', 'Aktivitas'),
  weighIn('weigh_in', 'Timbang berat'),
  sleep('sleep', 'Tidur'),
  foodLog('food_log', 'Catat makanan');

  const ReminderType(this.databaseValue, this.label);
  final String databaseValue;
  final String label;

  static ReminderType fromDatabase(String value) => values.firstWhere(
    (item) => item.databaseValue == value,
    orElse: () => ReminderType.foodLog,
  );
}

class LocalTime implements Comparable<LocalTime> {
  const LocalTime({required this.hour, required this.minute})
    : assert(hour >= 0 && hour <= 23),
      assert(minute >= 0 && minute <= 59);

  factory LocalTime.parse(String value) {
    final parts = value.split(':');
    return LocalTime(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  final int hour;
  final int minute;

  int get minutesSinceMidnight => hour * 60 + minute;

  String get databaseValue =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';

  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalTime other) =>
      minutesSinceMidnight.compareTo(other.minutesSinceMidnight);
}

class ScheduleEntry {
  const ScheduleEntry({
    required this.id,
    required this.userId,
    required this.dayOfWeek,
    required this.activityName,
    required this.startTime,
    required this.endTime,
    required this.category,
    required this.busynessLevel,
  });

  factory ScheduleEntry.fromJson(Map<String, Object?> json) => ScheduleEntry(
    id: json['id']! as String,
    userId: json['user_id']! as String,
    dayOfWeek: (json['day_of_week']! as num).toInt(),
    activityName: json['activity_name']! as String,
    startTime: LocalTime.parse(json['start_time']! as String),
    endTime: LocalTime.parse(json['end_time']! as String),
    category: ScheduleCategory.fromDatabase(json['category']! as String),
    busynessLevel: (json['busyness_level']! as num).toInt(),
  );

  final String id;
  final String userId;
  final int dayOfWeek;
  final String activityName;
  final LocalTime startTime;
  final LocalTime endTime;
  final ScheduleCategory category;
  final int busynessLevel;

  void validate() {
    if (dayOfWeek < 1 || dayOfWeek > 7) {
      throw ArgumentError.value(dayOfWeek, 'dayOfWeek');
    }
    if (activityName.trim().isEmpty || activityName.trim().length > 120) {
      throw ArgumentError.value(activityName, 'activityName');
    }
    if (startTime.compareTo(endTime) >= 0) {
      throw ArgumentError('Waktu selesai harus setelah waktu mulai.');
    }
    if (busynessLevel < 1 || busynessLevel > 3) {
      throw ArgumentError.value(busynessLevel, 'busynessLevel');
    }
  }

  Map<String, Object?> toWriteJson(String ownerId) => {
    'user_id': ownerId,
    'day_of_week': dayOfWeek,
    'activity_name': activityName.trim(),
    'start_time': startTime.databaseValue,
    'end_time': endTime.databaseValue,
    'category': category.databaseValue,
    'busyness_level': busynessLevel,
  };
}

class ReminderSetting {
  const ReminderSetting({
    required this.id,
    required this.userId,
    required this.type,
    required this.time,
    required this.enabled,
    required this.repeatDays,
  });

  factory ReminderSetting.fromJson(Map<String, Object?> json) =>
      ReminderSetting(
        id: json['id']! as String,
        userId: json['user_id']! as String,
        type: ReminderType.fromDatabase(json['reminder_type']! as String),
        time: LocalTime.parse(json['reminder_time']! as String),
        enabled: json['enabled']! as bool,
        repeatDays: (json['repeat_days']! as List<Object?>)
            .map((day) => (day! as num).toInt())
            .toList(growable: false),
      );

  final String id;
  final String userId;
  final ReminderType type;
  final LocalTime time;
  final bool enabled;
  final List<int> repeatDays;

  void validate() {
    final unique = repeatDays.toSet();
    if (unique.isEmpty ||
        unique.length != repeatDays.length ||
        unique.any((day) => day < 1 || day > 7)) {
      throw ArgumentError.value(repeatDays, 'repeatDays');
    }
  }

  ReminderSetting copyWith({bool? enabled}) => ReminderSetting(
    id: id,
    userId: userId,
    type: type,
    time: time,
    enabled: enabled ?? this.enabled,
    repeatDays: repeatDays,
  );

  Map<String, Object?> toWriteJson(String ownerId) => {
    'user_id': ownerId,
    'reminder_type': type.databaseValue,
    'reminder_time': time.databaseValue,
    'enabled': enabled,
    'repeat_days': repeatDays,
  };
}

class ScheduleGapAdvisor {
  const ScheduleGapAdvisor._();

  static String recommend(
    Iterable<ScheduleEntry> entries, {
    required int dayOfWeek,
  }) {
    final sorted =
        entries.where((entry) => entry.dayOfWeek == dayOfWeek).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    for (var index = 0; index < sorted.length - 1; index++) {
      final gapStart = sorted[index].endTime;
      final gapEnd = sorted[index + 1].startTime;
      final minutes =
          gapEnd.minutesSinceMidnight - gapStart.minutesSinceMidnight;
      if (minutes >= 20) {
        return 'Kamu punya waktu kosong sekitar ${gapStart.label}–${gapEnd.label}. '
            'Kamu bisa memilih jalan kaki selama 20 menit.';
      }
    }
    if (sorted.length >= 3 || sorted.any((entry) => entry.busynessLevel == 3)) {
      return 'Hari ini cukup padat. Aktivitas ringan 10–15 menit sudah cukup.';
    }
    return 'Belum ada cukup jadwal untuk menyarankan waktu aktivitas.';
  }
}
