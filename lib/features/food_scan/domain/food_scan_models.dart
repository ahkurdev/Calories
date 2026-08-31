import 'package:caloris/features/food/domain/food_models.dart';

enum ScanStatus {
  success('success'),
  notFood('not_food'),
  manualFallback('manual_fallback'),
  providerUnavailable('provider_unavailable');

  const ScanStatus(this.value);
  final String value;

  static ScanStatus fromValue(String value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => ScanStatus.providerUnavailable,
  );
}

class ScannedFoodItem {
  const ScannedFoodItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    required this.calories,
    required this.confidence,
    this.cookingMethod,
  });

  factory ScannedFoodItem.fromJson(Map<String, Object?> json, int index) =>
      ScannedFoodItem(
        id: (json['id'] as String?) ?? 'scan-item-$index',
        name: json['name']! as String,
        amount: ((json['amount'] ?? json['estimated_grams'])! as num)
            .toDouble(),
        unit: PortionUnit.fromDatabase((json['unit'] as String?) ?? 'gram'),
        calories: ((json['calories'] ?? json['estimated_calories'])! as num)
            .toDouble(),
        confidence: (json['confidence']! as num).toDouble(),
        cookingMethod: CookingMethod.fromDatabase(json['cooking_method']),
      );

  final String id;
  final String name;
  final double amount;
  final PortionUnit unit;
  final double calories;
  final double confidence;
  final CookingMethod? cookingMethod;

  ScannedFoodItem copyWith({
    String? name,
    double? amount,
    PortionUnit? unit,
    double? calories,
    double? confidence,
    CookingMethod? cookingMethod,
    bool clearCookingMethod = false,
  }) => ScannedFoodItem(
    id: id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    unit: unit ?? this.unit,
    calories: calories ?? this.calories,
    confidence: confidence ?? this.confidence,
    cookingMethod: clearCookingMethod
        ? null
        : cookingMethod ?? this.cookingMethod,
  );

  void validate() {
    if (name.trim().isEmpty || name.trim().length > 160) {
      throw ArgumentError.value(name, 'name');
    }
    if (amount <= 0 || amount > 100000) {
      throw ArgumentError.value(amount, 'amount');
    }
    if (calories < 0 || calories > 10000) {
      throw ArgumentError.value(calories, 'calories');
    }
    if (confidence < 0 || confidence > 1) {
      throw ArgumentError.value(confidence, 'confidence');
    }
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name.trim(),
    'amount': amount,
    'unit': unit.databaseValue,
    'calories': calories,
    'confidence': confidence,
    'cooking_method': cookingMethod?.databaseValue,
  };

  FoodLog toFoodLog(MealType mealType, DateTime loggedAt) => FoodLog(
    id: '',
    userId: '',
    mealType: mealType,
    foodName: name,
    amount: amount,
    unit: unit,
    calories: calories,
    cookingMethod: cookingMethod,
    loggedAt: loggedAt,
  );
}

class FoodScanResult {
  const FoodScanResult({
    required this.status,
    required this.foods,
    required this.notes,
    required this.isDevelopmentMock,
  });

  factory FoodScanResult.fromJson(
    Map<String, Object?> json, {
    bool isDevelopmentMock = false,
  }) {
    final rawFoods = (json['foods'] as List<Object?>?) ?? const [];
    return FoodScanResult(
      status: ScanStatus.fromValue(json['status']! as String),
      foods: [
        for (var index = 0; index < rawFoods.length; index++)
          ScannedFoodItem.fromJson(
            rawFoods[index]! as Map<String, Object?>,
            index,
          ),
      ],
      notes: (json['notes'] as String?) ?? 'Perkiraan berdasarkan foto.',
      isDevelopmentMock: isDevelopmentMock,
    );
  }

  final ScanStatus status;
  final List<ScannedFoodItem> foods;
  final String notes;
  final bool isDevelopmentMock;

  double get totalEstimatedCalories =>
      foods.fold(0, (total, food) => total + food.calories);

  FoodScanResult copyWith({List<ScannedFoodItem>? foods}) => FoodScanResult(
    status: status,
    foods: foods ?? this.foods,
    notes: notes,
    isDevelopmentMock: isDevelopmentMock,
  );

  void validate() {
    if (foods.length > 30 || notes.length > 1000) {
      throw ArgumentError('Hasil scan terlalu besar.');
    }
    for (final food in foods) {
      food.validate();
    }
  }

  Map<String, Object?> toJson() => {
    'status': status.value,
    'foods': foods.map((food) => food.toJson()).toList(growable: false),
    'total_estimated_calories': totalEstimatedCalories,
    'notes': notes,
    'is_development_mock': isDevelopmentMock,
  };
}

class ScanHistoryEntry {
  const ScanHistoryEntry({
    required this.id,
    required this.userId,
    required this.result,
    required this.scannedAt,
    this.imagePath,
  });

  factory ScanHistoryEntry.fromJson(Map<String, Object?> json) =>
      ScanHistoryEntry(
        id: json['id']! as String,
        userId: json['user_id']! as String,
        result: FoodScanResult.fromJson(
          json['scan_result']! as Map<String, Object?>,
        ),
        imagePath: json['image_path'] as String?,
        scannedAt: DateTime.parse(json['scanned_at']! as String),
      );

  final String id;
  final String userId;
  final FoodScanResult result;
  final String? imagePath;
  final DateTime scannedAt;
}
