import 'dart:convert';
import '../parsed_receipt.dart';

class AIService {
  // TODO: replace with real OpenAI/Vertex call
  Future<ParsedReceipt> extractFromImage({
    required String imageUrl,
    required String currencyFallback,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return ParsedReceipt(
      amount: 23.50,
      currency: currencyFallback,
      merchant: 'Supermercato XYZ',
      date: DateTime.now(),
      imageUrl: imageUrl,
      categorySuggestion: 'Spesa',
    );
  }
}
