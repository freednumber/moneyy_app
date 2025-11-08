import 'dart:io';
import '../parsed_receipt.dart';
import 'ocrspace_service.dart';
import 'storage_service.dart';

class ReceiptService {
  final StorageService storage;
  final OCRSpaceService ocr;

  ReceiptService({required this.storage, required this.ocr});

  Future<ParsedReceipt> processReceipt(File imageFile, {String currencyFallback = 'EUR'}) async {
    // Get temp URI (no permanent storage)
    final url = await storage.getImageUri(imageFile);
    
    // Extract data with OCR.space
    final parsed = await ocr.extractFromImage(imageUrl: url, currencyFallback: currencyFallback);
    
    return parsed;
  }
  
  // Clean up after transaction is saved
  Future<void> cleanupAfterSave(String imageUrl) async {
    await storage.cleanupTempFile(imageUrl);
  }
}
