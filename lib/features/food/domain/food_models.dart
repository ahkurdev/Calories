import 'dart:math' as math;

enum MealType {
  breakfast('breakfast', 'Sarapan'),
  lunch('lunch', 'Makan siang'),
  dinner('dinner', 'Makan malam'),
  snack('snack', 'Snack');

  const MealType(this.databaseValue, this.label);
  final String databaseValue;
  final String label;

  static MealType fromDatabase(String value) => values.firstWhere(
    (item) => item.databaseValue == value,
    orElse: () => MealType.snack,
  );
}

enum PortionUnit {
  gram('gram', 'gram'),
  kilogram('kilogram', 'kilogram'),
  milliliter('milliliter', 'ml'),
  tablespoon('tablespoon', 'sendok makan'),
  teaspoon('teaspoon', 'sendok teh'),
  piece('piece', 'potong'),
  bowl('bowl', 'mangkuk'),
  glass('glass', 'gelas'),
  plate('plate', 'piring'),
  fruit('fruit', 'buah'),
  halfPortion('half_portion', 'setengah porsi'),
  portion('portion', 'satu porsi');

  const PortionUnit(this.databaseValue, this.label);
  final String databaseValue;
  final String label;

  static PortionUnit fromDatabase(String value) => values.firstWhere(
    (item) => item.databaseValue == value,
    orElse: () => PortionUnit.portion,
  );
}

enum CookingMethod {
  boiled('boiled', 'Rebus'),
  steamed('steamed', 'Kukus'),
  grilled('grilled', 'Bakar'),
  baked('baked', 'Panggang'),
  stirFried('stir_fried', 'Tumis'),
  fried('fried', 'Goreng'),
  batteredFried('battered_fried', 'Goreng tepung'),
  other('other', 'Lainnya');

  const CookingMethod(this.databaseValue, this.label);
  final String databaseValue;
  final String label;

  static CookingMethod? fromDatabase(Object? value) {
    if (value is! String) return null;
    return values.firstWhere(
      (item) => item.databaseValue == value,
      orElse: () => CookingMethod.other,
    );
  }
}

class FoodLog {
  const FoodLog({
    required this.id,
    required this.userId,
    required this.mealType,
    required this.foodName,
    required this.amount,
    required this.unit,
    required this.calories,
    required this.loggedAt,
    this.protein = 0,
    this.carbohydrate = 0,
    this.fat = 0,
    this.fiber = 0,
    this.cookingMethod,
  });

  factory FoodLog.fromJson(Map<String, Object?> json) => FoodLog(
    id: json['id']! as String,
    userId: json['user_id']! as String,
    mealType: MealType.fromDatabase(json['meal_type']! as String),
    foodName: json['food_name']! as String,
    amount: (json['amount']! as num).toDouble(),
    unit: PortionUnit.fromDatabase(json['unit']! as String),
    calories: (json['calories']! as num).toDouble(),
    protein: (json['protein'] as num?)?.toDouble() ?? 0,
    carbohydrate: (json['carbohydrate'] as num?)?.toDouble() ?? 0,
    fat: (json['fat'] as num?)?.toDouble() ?? 0,
    fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
    cookingMethod: CookingMethod.fromDatabase(json['cooking_method']),
    loggedAt: DateTime.parse(json['logged_at']! as String),
  );

  final String id;
  final String userId;
  final MealType mealType;
  final String foodName;
  final double amount;
  final PortionUnit unit;
  final double calories;
  final double protein;
  final double carbohydrate;
  final double fat;
  final double fiber;
  final CookingMethod? cookingMethod;
  final DateTime loggedAt;

  FoodLog copyWith({
    String? id,
    String? userId,
    DateTime? loggedAt,
    MealType? mealType,
  }) => FoodLog(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    mealType: mealType ?? this.mealType,
    foodName: foodName,
    amount: amount,
    unit: unit,
    calories: calories,
    protein: protein,
    carbohydrate: carbohydrate,
    fat: fat,
    fiber: fiber,
    cookingMethod: cookingMethod,
    loggedAt: loggedAt ?? this.loggedAt,
  );

  Map<String, Object?> toInsertJson(String ownerId) => {
    'user_id': ownerId,
    'meal_type': mealType.databaseValue,
    'food_name': foodName.trim(),
    'amount': amount,
    'unit': unit.databaseValue,
    'calories': calories,
    'protein': protein,
    'carbohydrate': carbohydrate,
    'fat': fat,
    'fiber': fiber,
    'cooking_method': cookingMethod?.databaseValue,
    'logged_at': loggedAt.toUtc().toIso8601String(),
  };
}

class DailyFoodSummary {
  const DailyFoodSummary({
    required this.targetCalories,
    required this.consumedCalories,
    required this.remainingCalories,
    required this.overTargetCalories,
    required this.protein,
    required this.carbohydrate,
    required this.fat,
    required this.fiber,
  });

  factory DailyFoodSummary.fromLogs(
    Iterable<FoodLog> logs, {
    required int targetCalories,
  }) {
    var calories = 0.0;
    var protein = 0.0;
    var carbohydrate = 0.0;
    var fat = 0.0;
    var fiber = 0.0;
    for (final log in logs) {
      calories += log.calories;
      protein += log.protein;
      carbohydrate += log.carbohydrate;
      fat += log.fat;
      fiber += log.fiber;
    }
    final consumed = calories.round();
    return DailyFoodSummary(
      targetCalories: targetCalories,
      consumedCalories: consumed,
      remainingCalories: math.max(0, targetCalories - consumed),
      overTargetCalories: math.max(0, consumed - targetCalories),
      protein: protein,
      carbohydrate: carbohydrate,
      fat: fat,
      fiber: fiber,
    );
  }

  final int targetCalories;
  final int consumedCalories;
  final int remainingCalories;
  final int overTargetCalories;
  final double protein;
  final double carbohydrate;
  final double fat;
  final double fiber;

  double get progress =>
      targetCalories == 0 ? 0 : (consumedCalories / targetCalories).clamp(0, 1);
}

class FavoriteMeal {
  const FavoriteMeal({
    required this.id,
    required this.userId,
    required this.name,
    required this.items,
  });

  factory FavoriteMeal.fromJson(Map<String, Object?> json) {
    final mealData = json['meal_data']! as Map<String, Object?>;
    final rawItems = mealData['items']! as List<Object?>;
    return FavoriteMeal(
      id: json['id']! as String,
      userId: json['user_id']! as String,
      name: json['name']! as String,
      items: rawItems
          .map((item) => FoodTemplate.fromJson(item! as Map<String, Object?>))
          .toList(growable: false),
    );
  }

  final String id;
  final String userId;
  final String name;
  final List<FoodTemplate> items;

  Map<String, Object?> toInsertJson(String ownerId) => {
    'user_id': ownerId,
    'name': name.trim(),
    'meal_data': {
      'items': items.map((item) => item.toJson()).toList(growable: false),
    },
  };
}

class FoodTemplate {
  const FoodTemplate({
    required this.name,
    required this.amount,
    required this.unit,
    required this.calories,
    this.protein = 0,
    this.carbohydrate = 0,
    this.fat = 0,
    this.fiber = 0,
    this.cookingMethod,
  });

  factory FoodTemplate.fromJson(Map<String, Object?> json) => FoodTemplate(
    name: json['name']! as String,
    amount: (json['amount']! as num).toDouble(),
    unit: PortionUnit.fromDatabase(json['unit']! as String),
    calories: (json['calories']! as num).toDouble(),
    protein: (json['protein'] as num?)?.toDouble() ?? 0,
    carbohydrate: (json['carbohydrate'] as num?)?.toDouble() ?? 0,
    fat: (json['fat'] as num?)?.toDouble() ?? 0,
    fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
    cookingMethod: CookingMethod.fromDatabase(json['cooking_method']),
  );

  final String name;
  final double amount;
  final PortionUnit unit;
  final double calories;
  final double protein;
  final double carbohydrate;
  final double fat;
  final double fiber;
  final CookingMethod? cookingMethod;

  Map<String, Object?> toJson() => {
    'name': name,
    'amount': amount,
    'unit': unit.databaseValue,
    'calories': calories,
    'protein': protein,
    'carbohydrate': carbohydrate,
    'fat': fat,
    'fiber': fiber,
    'cooking_method': cookingMethod?.databaseValue,
  };

  FoodLog toLog({
    required String userId,
    required MealType mealType,
    required DateTime loggedAt,
  }) => FoodLog(
    id: '',
    userId: userId,
    mealType: mealType,
    foodName: name,
    amount: amount,
    unit: unit,
    calories: calories,
    protein: protein,
    carbohydrate: carbohydrate,
    fat: fat,
    fiber: fiber,
    cookingMethod: cookingMethod,
    loggedAt: loggedAt,
  );
}
