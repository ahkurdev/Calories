import 'package:caloris/features/recommendations/domain/recommendation_models.dart';

class RecommendationFunctionParser {
  const RecommendationFunctionParser._();

  static RecommendationResult parse(
    Map<String, Object?> json, {
    required String contentKey,
  }) {
    final status = json['status'];
    if (status == 'success') {
      final content = json[contentKey];
      if (content is String &&
          content.trim().isNotEmpty &&
          content.length <= 4000) {
        return RecommendationResult(
          status: RecommendationStatus.success,
          message: content.trim(),
          foodsToChoose: _guidanceItems(json['foods_to_choose']),
          foodsToLimit: _guidanceItems(json['foods_to_limit']),
          disclaimer: _boundedText(json['disclaimer'], maxLength: 500),
        );
      }
      return const RecommendationResult.manualFallback(
        'Respons insight AI tidak valid. Statistik dasarmu tetap tersedia.',
      );
    }
    final message = json['message'];
    if (status == 'out_of_scope') {
      return RecommendationResult(
        status: RecommendationStatus.outOfScope,
        message: message is String && message.trim().isNotEmpty
            ? message.trim()
            : 'Permintaan berada di luar cakupan Caloris.',
      );
    }
    return RecommendationResult.manualFallback(
      message is String && message.trim().isNotEmpty ? message.trim() : null,
    );
  }

  static List<FoodGuidanceItem> _guidanceItems(Object? value) {
    if (value is! List<Object?> || value.length > 8) return const [];
    final items = <FoodGuidanceItem>[];
    for (final raw in value) {
      if (raw is! Map<Object?, Object?>) return const [];
      final name = _boundedText(raw['name'], maxLength: 120);
      final reason = _boundedText(raw['reason'], maxLength: 300);
      if (name.isEmpty || reason.isEmpty) return const [];
      items.add(FoodGuidanceItem(name: name, reason: reason));
    }
    return List.unmodifiable(items);
  }

  static String _boundedText(Object? value, {required int maxLength}) {
    if (value is! String || value.trim().isEmpty || value.length > maxLength) {
      return '';
    }
    return value.trim();
  }
}
