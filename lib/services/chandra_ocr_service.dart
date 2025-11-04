import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ChandraOCRService {
  // Configurabile: localhost per dev, deployed URL per produzione
  static const String _baseUrl = kDebugMode 
    ? 'http://localhost:3000' 
    : 'https://your-deployed-backend.railway.app';
  
  /// Processa uno scontrino usando Chandra OCR e restituisce dati estratti
  static Future<ReceiptData> processReceipt(File imageFile) async {
    try {
      debugPrint('📸 Processing receipt with Chandra OCR...');
      
      // Converti immagine a base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Chiamata al backend
      final response = await http.post(
        Uri.parse('$_baseUrl/api/ocr/receipt'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'imageBase64': 'data:image/jpeg;base64,$base64Image'
        }),
      ).timeout(const Duration(minutes: 3)); // Timeout generoso per OCR
      
      if (response.statusCode != 200) {
        throw OCRException('Backend error: ${response.statusCode}');
      }
      
      final data = jsonDecode(response.body);
      
      if (!data['success']) {
        throw OCRException(data['error'] ?? 'Unknown OCR error');
      }
      
      debugPrint('✅ Chandra OCR completed with confidence: ${data['confidence']}');
      
      return ReceiptData.fromJson(data);
      
    } on http.ClientException catch (e) {
      throw OCRException('Network error: Check backend connection ($e)');
    } on FormatException catch (e) {
      throw OCRException('Invalid response format: $e');
    } catch (e) {
      throw OCRException('Processing failed: $e');
    }
  }
  
  /// Test di connessione al backend
  static Future<bool> checkBackendHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'OK';
      }
      return false;
    } catch (e) {
      debugPrint('❌ Backend health check failed: $e');
      return false;
    }
  }
  
  /// Fallback: simulazione per sviluppo senza backend
  static Future<ReceiptData> simulateProcessing() async {
    await Future.delayed(const Duration(seconds: 2));
    
    return ReceiptData(
      merchant: 'CONAD SUPERSTORE',
      date: DateTime.now(),
      total: 45.67,
      currency: 'EUR',
      category: 'Spesa',
      items: [
        ReceiptItem(
          name: 'Pasta Barilla 500g',
          quantity: 2,
          unitPrice: 1.20,
          lineTotal: 2.40,
        ),
        ReceiptItem(
          name: 'Latte Fresco 1L',
          quantity: 1,
          unitPrice: 1.45,
          lineTotal: 1.45,
        ),
      ],
      confidence: 0.95,
    );
  }
}

/// Dati estratti da uno scontrino
class ReceiptData {
  final String merchant;
  final DateTime date;
  final double total;
  final String currency;
  final String category;
  final List<ReceiptItem> items;
  final double confidence;
  
  ReceiptData({
    required this.merchant,
    required this.date,
    required this.total,
    required this.currency,
    required this.category,
    required this.items,
    required this.confidence,
  });
  
  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      merchant: json['merchant'] ?? 'Negozio Non Identificato',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      total: (json['total'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'EUR',
      category: json['category'] ?? 'Altro',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => ReceiptItem.fromJson(item))
          .toList(),
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}

/// Item di uno scontrino
class ReceiptItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  
  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });
  
  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      lineTotal: (json['lineTotal'] ?? 0).toDouble(),
    );
  }
}

/// Eccezione personalizzata per errori OCR
class OCRException implements Exception {
  final String message;
  OCRException(this.message);
  
  @override
  String toString() => 'OCRException: $message';
}