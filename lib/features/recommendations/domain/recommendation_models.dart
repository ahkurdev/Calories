import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/profile/domain/user_profile.dart';
import 'package:caloris/features/schedule/domain/schedule_models.dart';

enum RecommendationStatus { success, manualFallback, outOfScope }

class RecommendationResult {
  const RecommendationResult({
    required this.status,
    required this.message,
    this.foodsToChoose = const [],
    this.foodsToLimit = const [],
    this.disclaimer = '',
  });

  const RecommendationResult.manualFallback([String? message])
    : status = RecommendationStatus.manualFallback,
      message = message ?? 'Insight AI sedang tidak tersedia. Statistik dasarmu tetap dapat dilihat.',
      foodsToChoose = const [],
      foodsToLimit = const [],
      disclaimer = '';

  final RecommendationStatus status;
  final String message;
  final List<FoodGuidanceItem> foodsToChoose;
  final List<FoodGuidanceItem> foodsToLimit;
  final String disclaimer;

  bool get isAiGenerated => status == RecommendationStatus.success;
}

class FoodGuidanceItem {
  const FoodGuidanceItem({required this.name, required this.reason});

  final String name;
  final String reason;
}

enum FoodConversationRole {
  user,
  assistant;

  String get value => name;
}

class FoodConversationMessage {
  const FoodConversationMessage({required this.role, required this.content});

  final FoodConversationRole role;
  final String content;

  Map<String, String> toJson() => {
    'role': role.value,
    'content': content.trim(),
  };
}

class NearbyFoodPlace {
  const NearbyFoodPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.mapsUri,
    required this.websiteUri,
    required this.rating,
    required this.userRatingCount,
    required this.priceLevel,
    required this.openNow,
    required this.delivery,
    required this.takeout,
    required this.dineIn,
  });

  final String id;
  final String name;
  final String address;
  final String mapsUri;
  final String websiteUri;
  final double? rating;
  final int userRatingCount;
  final String priceLevel;
  final bool? openNow;
  final bool delivery;
  final bool takeout;
  final bool dineIn;

  Map<String, Object?> toAiJson() => {
    'name': name,
    'address': address,
    'rating': rating,
    'priceLevel': priceLevel,
    'openNow': openNow,
    'delivery': delivery,
    'takeout': takeout,
    'dineIn': dineIn,
  };
}

enum NearbyFoodStatus { success, configurationRequired, unavailable }

class NearbyFoodSearchResult {
  const NearbyFoodSearchResult({
    required this.status,
    required this.message,
    this.places = const [],
  });

  final NearbyFoodStatus status;
  final String message;
  final List<NearbyFoodPlace> places;
}

class FoodHistoryItem {
  const FoodHistoryItem({
    required this.name,
    required this.calories,
    required this.mealType,
  });

  factory FoodHistoryItem.fromLog(FoodLog log) => FoodHistoryItem(
    name: log.foodName,
    calories: log.calories,
    mealType: log.mealType,
  );

  final String name;
  final double calories;
  final MealType mealType;

  Map<String, Object?> toJson() => {
    'name': name.trim(),
    'calories': calories,
    'mealType': mealType.databaseValue,
  };
}

class MealRecommendationRequest {
  const MealRecommendationRequest({
    required this.remainingCalories,
    required this.goal,
    required this.mealType,
    required this.preference,
    required this.practicalMode,
    required this.foodHistory,
    this.question = '',
    this.conversation = const [],
    this.preferredFoods = const [],
    this.limitedFoods = const [],
    this.nearbyPlaces = const [],
  });

  final int remainingCalories;
  final HealthGoal goal;
  final MealType mealType;
  final String preference;
  final bool practicalMode;
  final List<FoodHistoryItem> foodHistory;
  final String question;
  final List<FoodConversationMessage> conversation;
  final List<String> preferredFoods;
  final List<String> limitedFoods;
  final List<NearbyFoodPlace> nearbyPlaces;

  Map<String, Object?> toInputJson() => {
    'remainingCalories': remainingCalories.clamp(0, 10000),
    'goal': goal.databaseValue,
    'mealType': mealType.databaseValue,
    'preference': preference.trim(),
    'foodHistory': foodHistory
        .take(30)
        .map((item) => item.toJson())
        .toList(growable: false),
    'practicalMode': practicalMode,
    'question': question.trim(),
    'conversation': conversation
        .skip(conversation.length > 8 ? conversation.length - 8 : 0)
        .map((message) => message.toJson())
        .toList(growable: false),
    'preferredFoods': preferredFoods
        .map((food) => food.trim())
        .where((food) => food.isNotEmpty)
        .take(20)
        .toList(growable: false),
    'limitedFoods': limitedFoods
        .map((food) => food.trim())
        .where((food) => food.isNotEmpty)
        .take(20)
        .toList(growable: false),
    'nearbyPlaces': nearbyPlaces
        .take(8)
        .map((place) => place.toAiJson())
        .toList(growable: false),
  };
}

class ActivityRecommendationRequest {
  const ActivityRecommendationRequest({
    required this.dayOfWeek,
    required this.schedules,
  });

  final int dayOfWeek;
  final List<ScheduleEntry> schedules;

  Map<String, Object?> toInputJson() => {
    'dayOfWeek': dayOfWeek,
    'schedules': schedules
        .where((entry) => entry.dayOfWeek == dayOfWeek)
        .take(30)
        .map(
          (entry) => {
            'activityName': entry.activityName,
            'dayOfWeek': entry.dayOfWeek,
            'startTime': entry.startTime.label,
            'endTime': entry.endTime.label,
            'category': entry.category.databaseValue,
            'busynessLevel': entry.busynessLevel,
          },
        )
        .toList(growable: false),
  };
}
