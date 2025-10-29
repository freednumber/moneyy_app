import 'dart:io';
import '../parsed_receipt.dart';
import 'ai_service.dart';
import 'storage_service.dart';

class ReceiptService {
  final StorageService storage;
  final AIService ai;

  ReceiptService({required this.storage, required this.ai});

  Future<ParsedReceipt> processReceipt(File imageFile, {String currencyFallback = 'EUR'}) async {
    // Get temp URI (no permanent storage)
    final url = await storage.getImageUri(imageFile);
    
    // Extract data with Google Vision
    final parsed = await ai.extractFromImage(imageUrl: url, currencyFallback: currencyFallback);
    
    return parsed;
  }
  
  // Clean up after transaction is saved
  Future<void> cleanupAfterSave(String imageUrl) async {
    await storage.cleanupTempFile(imageUrl);
  }
}
