import 'package:caloris/core/services/calorie_calculator_service.dart';
import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/profile/domain/user_profile.dart';
import 'package:caloris/features/profile/presentation/controllers/profile_controller.dart';
import 'package:caloris/features/recommendations/data/supabase_insights_repository.dart';
import 'package:caloris/features/recommendations/data/supabase_nearby_food_repository.dart';
import 'package:caloris/features/recommendations/data/supabase_recommendation_repository.dart';
import 'package:caloris/features/recommendations/domain/health_statistics.dart';
import 'package:caloris/features/recommendations/domain/recommendation_models.dart';
import 'package:caloris/features/recommendations/services/health_statistics_service.dart';
import 'package:caloris/features/schedule/domain/schedule_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class HealthInsightsSnapshot {
  const HealthInsightsSnapshot({
    required this.daily,
    required this.weekly,
    required this.goal,
    required this.foodHistory,
    required this.schedules,
  });

  final DailyHealthStatistics daily;
  final WeeklyHealthStatistics weekly;
  final HealthGoal goal;
  final List<FoodLog> foodHistory;
  final List<ScheduleEntry> schedules;
}

final healthInsightsProvider = FutureProvider<HealthInsightsSnapshot>((
  ref,
) async {
  final profile = await ref.watch(profileControllerProvider.future);
  if (profile == null) throw StateError('Profil belum tersedia.');
  final calculation = const CalorieCalculatorService().calculate(
    gender: profile.gender,
    age: profile.age,
    heightCm: profile.heightCm,
    weightKg: profile.currentWeightKg,
    activityLevel: profile.activityLevel,
    goal: profile.goal,
  );
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(const Duration(days: 6));
  final end = today.add(const Duration(days: 1));
  final data = await ref
      .watch(insightsRepositoryProvider)
      .loadRange(start: start, endExclusive: end);
  const statistics = HealthStatisticsService();
  return HealthInsightsSnapshot(
    daily: statistics.daily(
      day: today,
      targetCalories: calculation.targetCalories,
      waterTargetMl: profile.waterTargetMl,
      foods: data.foods,
      water: data.water,
      activities: data.activities,
    ),
    weekly: statistics.weekly(
      start: start,
      endExclusive: end,
      targetCalories: calculation.targetCalories,
      foods: data.foods,
      water: data.water,
      activities: data.activities,
      weights: data.weights,
    ),
    goal: profile.goal,
    foodHistory: data.foods,
    schedules: data.schedules,
  );
});

enum RecommendationKind { meal, activity, dailySummary, weeklySummary }

class RecommendationsState {
  const RecommendationsState({
    this.results = const {},
    this.loading = const {},
  });

  final Map<RecommendationKind, RecommendationResult> results;
  final Set<RecommendationKind> loading;

  RecommendationsState copyWith({
    Map<RecommendationKind, RecommendationResult>? results,
    Set<RecommendationKind>? loading,
  }) => RecommendationsState(
    results: results ?? this.results,
    loading: loading ?? this.loading,
  );
}

final recommendationsControllerProvider =
    NotifierProvider<RecommendationsController, RecommendationsState>(
      RecommendationsController.new,
    );

class RecommendationsController extends Notifier<RecommendationsState> {
  @override
  RecommendationsState build() => const RecommendationsState();

  Future<void> recommendMeal(
    HealthInsightsSnapshot snapshot, {
    required MealType mealType,
    required String preference,
    required bool practicalMode,
  }) {
    final history = snapshot.foodHistory.toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return _run(
      RecommendationKind.meal,
      () => ref
          .read(recommendationRepositoryProvider)
          .recommendMeal(
            MealRecommendationRequest(
              remainingCalories: snapshot.daily.remainingCalories,
              goal: snapshot.goal,
              mealType: mealType,
              preference: preference,
              practicalMode: practicalMode,
              foodHistory: history
                  .take(30)
                  .map(FoodHistoryItem.fromLog)
                  .toList(growable: false),
            ),
          ),
    );
  }

  Future<void> recommendActivity(HealthInsightsSnapshot snapshot) => _run(
    RecommendationKind.activity,
    () => ref
        .read(recommendationRepositoryProvider)
        .recommendActivity(
          ActivityRecommendationRequest(
            dayOfWeek: snapshot.daily.day.weekday,
            schedules: snapshot.schedules,
          ),
        ),
  );

  Future<void> generateDailySummary(HealthInsightsSnapshot snapshot) => _run(
    RecommendationKind.dailySummary,
    () => ref
        .read(recommendationRepositoryProvider)
        .generateDailySummary(snapshot.daily),
  );

  Future<void> generateWeeklySummary(HealthInsightsSnapshot snapshot) => _run(
    RecommendationKind.weeklySummary,
    () => ref
        .read(recommendationRepositoryProvider)
        .generateWeeklySummary(snapshot.weekly),
  );

  Future<void> _run(
    RecommendationKind kind,
    Future<RecommendationResult> Function() operation,
  ) async {
    state = state.copyWith(loading: {...state.loading, kind});
    RecommendationResult result;
    try {
      result = await operation();
    } on Object {
      result = const RecommendationResult.manualFallback();
    }
    final loading = {...state.loading}..remove(kind);
    state = state.copyWith(
      results: {...state.results, kind: result},
      loading: loading,
    );
  }
}

class FoodAssistantState {
  const FoodAssistantState({
    this.messages = const [],
    this.latestResult,
    this.isLoading = false,
    this.nearbyPlaces = const [],
    this.isLoadingNearby = false,
    this.nearbyMessage,
  });

  final List<FoodConversationMessage> messages;
  final RecommendationResult? latestResult;
  final bool isLoading;
  final List<NearbyFoodPlace> nearbyPlaces;
  final bool isLoadingNearby;
  final String? nearbyMessage;

  FoodAssistantState copyWith({
    List<FoodConversationMessage>? messages,
    RecommendationResult? latestResult,
    bool? isLoading,
    List<NearbyFoodPlace>? nearbyPlaces,
    bool? isLoadingNearby,
    String? nearbyMessage,
    bool clearNearbyMessage = false,
    bool clearResult = false,
  }) => FoodAssistantState(
    messages: messages ?? this.messages,
    latestResult: clearResult ? null : latestResult ?? this.latestResult,
    isLoading: isLoading ?? this.isLoading,
    nearbyPlaces: nearbyPlaces ?? this.nearbyPlaces,
    isLoadingNearby: isLoadingNearby ?? this.isLoadingNearby,
    nearbyMessage: clearNearbyMessage
        ? null
        : nearbyMessage ?? this.nearbyMessage,
  );
}

final foodAssistantControllerProvider =
    NotifierProvider<FoodAssistantController, FoodAssistantState>(
      FoodAssistantController.new,
    );

class FoodAssistantController extends Notifier<FoodAssistantState> {
  @override
  FoodAssistantState build() => const FoodAssistantState();

  Future<void> send(
    HealthInsightsSnapshot snapshot, {
    required String question,
    required MealType mealType,
    required List<String> preferredFoods,
    required List<String> limitedFoods,
    required bool practicalMode,
    String preference = '',
  }) async {
    final cleanQuestion = question.trim();
    if (cleanQuestion.isEmpty || state.isLoading) return;
    final previousMessages = state.messages;
    final userMessage = FoodConversationMessage(
      role: FoodConversationRole.user,
      content: cleanQuestion,
    );
    state = state.copyWith(
      messages: _boundedMessages([...previousMessages, userMessage]),
      isLoading: true,
      clearResult: true,
    );

    final history = snapshot.foodHistory.toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    RecommendationResult result;
    try {
      result = await ref
          .read(recommendationRepositoryProvider)
          .recommendMeal(
            MealRecommendationRequest(
              remainingCalories: snapshot.daily.remainingCalories,
              goal: snapshot.goal,
              mealType: mealType,
              preference: preference,
              practicalMode: practicalMode,
              foodHistory: history
                  .take(30)
                  .map(FoodHistoryItem.fromLog)
                  .toList(growable: false),
              question: cleanQuestion,
              conversation: previousMessages.length > 8
                  ? previousMessages.sublist(previousMessages.length - 8)
                  : previousMessages,
              preferredFoods: preferredFoods,
              limitedFoods: limitedFoods,
              nearbyPlaces: state.nearbyPlaces,
            ),
          );
    } on Object {
      result = const RecommendationResult.manualFallback(
        'Asisten makanan sedang tidak tersedia. Coba lagi beberapa saat.',
      );
    }

    final assistantMessage = FoodConversationMessage(
      role: FoodConversationRole.assistant,
      content: result.message,
    );
    state = state.copyWith(
      messages: _boundedMessages([...state.messages, assistantMessage]),
      latestResult: result,
      isLoading: false,
    );
  }

  void clear() => state = const FoodAssistantState();

  Future<void> findNearbyFoods() async {
    if (state.isLoadingNearby) return;
    state = state.copyWith(isLoadingNearby: true, clearNearbyMessage: true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        state = state.copyWith(
          isLoadingNearby: false,
          nearbyMessage:
              'Aktifkan layanan lokasi untuk mencari tempat sekitar.',
        );
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLoadingNearby: false,
          nearbyMessage:
              'Izin lokasi diperlukan hanya saat mencari tempat makan sekitar.',
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final result = await ref
          .read(nearbyFoodRepositoryProvider)
          .search(
            latitude: position.latitude,
            longitude: position.longitude,
            radiusMeters: 1500,
          );
      state = state.copyWith(
        isLoadingNearby: false,
        nearbyPlaces: result.places,
        nearbyMessage: result.message,
      );
    } on Object {
      state = state.copyWith(
        isLoadingNearby: false,
        nearbyMessage: 'Lokasi atau tempat sekitar belum dapat dimuat. Coba buka Google Maps.',
      );
    }
  }

  List<FoodConversationMessage> _boundedMessages(
    List<FoodConversationMessage> messages,
  ) => List.unmodifiable(
    messages.length > 20 ? messages.sublist(messages.length - 20) : messages,
  );
}
