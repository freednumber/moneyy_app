import 'dart:io';
import '../parsed_receipt.dart';
import 'ai_service.dart';
import 'storage_service.dart';

class ReceiptService {
  final StorageService storage;
  final AIService ai;

  ReceiptService({required this.storage, required this.ai});

  Future<ParsedReceipt> processReceipt(File imageFile, {String currencyFallback = 'EUR'}) async {
    final url = await storage.saveReceiptImage(imageFile);
    final parsed = await ai.extractFromImage(imageUrl: url, currencyFallback: currencyFallback);
    return parsed;
  }
}
