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
}
