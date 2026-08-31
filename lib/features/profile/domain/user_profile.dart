import 'package:caloris/core/errors/app_failure.dart';

enum Gender {
  female('female', 'Perempuan'),
  male('male', 'Laki-laki'),
  other('other', 'Lainnya'),
  preferNotToSay('prefer_not_to_say', 'Tidak ingin menyebutkan');

  const Gender(this.databaseValue, this.label);
  final String databaseValue;
  final String label;

  static Gender fromDatabase(String value) => values.firstWhere(
    (item) => item.databaseValue == value,
    orElse: () => Gender.preferNotToSay,
  );
}

enum ActivityLevel {
  sedentary('sedentary', 'Jarang aktif'),
  lightlyActive('lightly_active', 'Aktif ringan'),
  moderatelyActive('moderately_active', 'Cukup aktif'),
  veryActive('very_active', 'Sangat aktif');

  const ActivityLevel(this.databaseValue, this.label);
  final String databaseValue;
  final String label;

  static ActivityLevel fromDatabase(String value) => values.firstWhere(
    (item) => item.databaseValue == value,
    orElse: () => ActivityLevel.sedentary,
  );
}

enum HealthGoal {
  loseWeight('lose_weight', 'Menurunkan berat badan'),
  maintainWeight('maintain_weight', 'Mempertahankan berat badan'),
  gainWeight('gain_weight', 'Menaikkan berat badan');

  const HealthGoal(this.databaseValue, this.label);
  final String databaseValue;
  final String label;

  static HealthGoal fromDatabase(String value) => values.firstWhere(
    (item) => item.databaseValue == value,
    orElse: () => HealthGoal.maintainWeight,
  );
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.gender,
    required this.birthDate,
    required this.heightCm,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.activityLevel,
    required this.goal,
    this.waterTargetMl = 2000,
  });

  factory UserProfile.fromJson(Map<String, Object?> json) => UserProfile(
    id: json['id']! as String,
    name: json['name']! as String,
    gender: Gender.fromDatabase(json['gender']! as String),
    birthDate: DateTime.parse(json['birth_date']! as String),
    heightCm: (json['height_cm']! as num).toDouble(),
    currentWeightKg: (json['current_weight_kg']! as num).toDouble(),
    targetWeightKg: (json['target_weight_kg']! as num).toDouble(),
    activityLevel: ActivityLevel.fromDatabase(
      json['activity_level']! as String,
    ),
    goal: HealthGoal.fromDatabase(json['goal']! as String),
    waterTargetMl: (json['water_target_ml'] as num?)?.toInt() ?? 2000,
  );

  final String id;
  final String name;
  final Gender gender;
  final DateTime birthDate;
  final double heightCm;
  final double currentWeightKg;
  final double targetWeightKg;
  final ActivityLevel activityLevel;
  final HealthGoal goal;
  final int waterTargetMl;

  int get age {
    final today = DateTime.now();
    var years = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      years--;
    }
    return years;
  }

  UserProfile copyWith({String? id}) => UserProfile(
    id: id ?? this.id,
    name: name,
    gender: gender,
    birthDate: birthDate,
    heightCm: heightCm,
    currentWeightKg: currentWeightKg,
    targetWeightKg: targetWeightKg,
    activityLevel: activityLevel,
    goal: goal,
    waterTargetMl: waterTargetMl,
  );

  void validate() {
    if (name.trim().length < 2 || name.trim().length > 80) {
      throw const ValidationFailure('Nama harus terdiri dari 2–80 karakter.');
    }
    if (age < 13 || age > 100) {
      throw const ValidationFailure('Usia harus berada antara 13–100 tahun.');
    }
    if (heightCm < 100 || heightCm > 250) {
      throw const ValidationFailure('Tinggi harus berada antara 100–250 cm.');
    }
    if (currentWeightKg < 25 || currentWeightKg > 400) {
      throw const ValidationFailure(
        'Berat saat ini harus berada antara 25–400 kg.',
      );
    }
    if (targetWeightKg < 25 || targetWeightKg > 400) {
      throw const ValidationFailure(
        'Target berat harus berada antara 25–400 kg.',
      );
    }
    if (waterTargetMl < 250 || waterTargetMl > 10000) {
      throw const ValidationFailure(
        'Target air harus berada antara 250–10.000 ml.',
      );
    }
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name.trim(),
    'gender': gender.databaseValue,
    'birth_date': _dateOnly(birthDate),
    'height_cm': heightCm,
    'current_weight_kg': currentWeightKg,
    'target_weight_kg': targetWeightKg,
    'activity_level': activityLevel.databaseValue,
    'goal': goal.databaseValue,
    'water_target_ml': waterTargetMl,
  };

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
