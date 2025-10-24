import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../config/api_keys.dart';
import '../parsed_receipt.dart';

class AIService {
  static const String _visionEndpoint = 'https://vision.googleapis.com/v1/images:annotate';
  late final TextRecognizer _textRecognizer;

  AIService() {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  void dispose() {
    _textRecognizer.close();
  }

  Future<ParsedReceipt> extractFromImage({
    required String imageUrl,
    required String currencyFallback,
  }) async {
    try {
      // Try Google Vision API first
      return await _extractWithGoogleVision(imageUrl, currencyFallback);
    } catch (e) {
      print('Google Vision failed: $e');
      
      // Check if it's a 403/401 error (authentication/permission issue)
      if (e.toString().contains('403') || e.toString().contains('401')) {
        print('Using ML Kit fallback due to Vision API authentication error');
        return await _extractWithMLKit(imageUrl, currencyFallback, isVisionError: true);
      }
      
      // For other errors, also use ML Kit but don't mark as Vision error
      print('Using ML Kit fallback due to network/other error');
      return await _extractWithMLKit(imageUrl, currencyFallback, isVisionError: false);
    }
  }

  Future<ParsedReceipt> _extractWithGoogleVision(String imageUrl, String currencyFallback) async {
    // Read and encode image with size optimization
    String base64Image;
    if (imageUrl.startsWith('file://')) {
      final file = File(Uri.parse(imageUrl).toFilePath());
      final bytes = await file.readAsBytes();
      
      // Optimize image size for Vision API
      final optimizedBytes = await _optimizeImageForVision(bytes);
      base64Image = base64Encode(optimizedBytes);
    } else {
      throw Exception('Only local files supported');
    }

    final response = await http.post(
      Uri.parse('$_visionEndpoint?key=${ApiKeys.googleVisionApiKey}'),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'MoneyY/1.0.0',
      },
      body: jsonEncode({
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'TEXT_DETECTION', 'maxResults': 1}
            ]
          }
        ]
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 403) {
      throw Exception('Vision API error: 403 - Check API key permissions, billing, and quota');
    } else if (response.statusCode == 401) {
      throw Exception('Vision API error: 401 - Invalid API key');
    } else if (response.statusCode != 200) {
      throw Exception('Vision API error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    final textAnnotations = data['responses']?[0]?['textAnnotations'];
    
    if (textAnnotations == null || textAnnotations.isEmpty) {
      throw Exception('No text detected in image by Google Vision');
    }

    final fullText = textAnnotations[0]['description'] as String;
    return _parseReceiptText(fullText, imageUrl, currencyFallback, ocrSource: 'Google Vision');
  }

  Future<ParsedReceipt> _extractWithMLKit(String imageUrl, String currencyFallback, {required bool isVisionError}) async {
    if (!imageUrl.startsWith('file://')) {
      throw Exception('ML Kit requires local file');
    }

    final file = File(Uri.parse(imageUrl).toFilePath());
    final inputImage = InputImage.fromFile(file);
    
    final recognizedText = await _textRecognizer.processImage(inputImage);
    
    if (recognizedText.text.isEmpty) {
      return ParsedReceipt(
        amount: 0.0,
        currency: currencyFallback,
        merchant: isVisionError ? 'OCR Locale - Vision API non disponibile' : 'OCR Locale',
        date: DateTime.now(),
        imageUrl: imageUrl,
        categorySuggestion: 'Altro',
        hasVisionError: isVisionError,
      );
    }

    final ocrSource = isVisionError ? 'ML Kit (Vision API non disponibile)' : 'ML Kit';
    return _parseReceiptText(recognizedText.text, imageUrl, currencyFallback, ocrSource: ocrSource, hasVisionError: isVisionError);
  }

  Future<Uint8List> _optimizeImageForVision(Uint8List originalBytes) async {
    // If image is larger than 4MB, we should compress it
    // For now, just return original - could add image compression here
    const maxSizeBytes = 4 * 1024 * 1024; // 4MB
    
    if (originalBytes.length > maxSizeBytes) {
      print('Image size ${originalBytes.length} bytes exceeds 4MB, should compress');
      // TODO: Add image compression using flutter's image library
      return originalBytes;
    }
    
    return originalBytes;
  }

  ParsedReceipt _parseReceiptText(String text, String imageUrl, String currency, {required String ocrSource, bool hasVisionError = false}) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    
    // Extract amount
    double amount = _extractAmount(lines);
    
    // Extract merchant (first non-numeric line, usually at top)
    String merchant = _extractMerchant(lines, ocrSource);
    
    // Extract date
    DateTime date = _extractDate(lines) ?? DateTime.now();
    
    // Suggest category based on merchant
    String category = _suggestCategory(merchant, lines);
    
    return ParsedReceipt(
      amount: amount,
      currency: currency,
      merchant: merchant,
      date: date,
      imageUrl: imageUrl,
      categorySuggestion: category,
      hasVisionError: hasVisionError,
    );
  }

  double _extractAmount(List<String> lines) {
    final patterns = <RegExp>[
      RegExp(r'total[e]?[:\s]+([0-9]+[,.]?[0-9]*)', caseSensitive: false),
      RegExp(r'totale[:\s]+([0-9]+[,.]?[0-9]*)', caseSensitive: false),
      RegExp(r'\€\s*([0-9]+[,.]?[0-9]*)', caseSensitive: false),
      RegExp(r'([0-9]+[,.]?[0-9]*)\s*\€', caseSensitive: false),
      RegExp(r'([0-9]+[,.]?[0-9]*)\s*eur', caseSensitive: false),
    ];
    
    for (final line in lines.reversed) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final amountStr = match.group(1)!.replaceAll(',', '.');
          final val = double.tryParse(amountStr);
          if (val != null && val > 0) return val;
        }
      }
    }
    
    // Fallback: find largest reasonable number in text
    final numbers = RegExp(r'([0-9]+[,.]?[0-9]*)')
        .allMatches(lines.join(' '))
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 0.0)
        .where((n) => n > 0 && n < 10000) // Reasonable receipt amounts
        .toList();
    
    return numbers.isNotEmpty ? numbers.reduce((a, b) => a > b ? a : b) : 0.0;
  }

  String _extractMerchant(List<String> lines, String ocrSource) {
    final ignoreWords = {'scontrino', 'ricevuta', 'receipt', 'fiscal', 'via', 'tel', 'p.iva', 'partita', 'iva', 'codice', 'cf'};
    
    for (final line in lines.take(8)) { // Check more lines for merchant
      final lower = line.toLowerCase();
      if (ignoreWords.any((w) => lower.contains(w))) continue;
      if (line.length < 3 || line.length > 35) continue;
      if (RegExp(r'^[0-9\s.,€-]+$').hasMatch(line)) continue; // Skip number-only lines
      
      // Clean up the merchant name
      final cleaned = line.replaceAll(RegExp(r'[^a-zA-ZÀ-ÿ0-9\s]'), ' ').trim();
      if (cleaned.length >= 3) {
        return cleaned.length > 25 ? '${cleaned.substring(0, 25)}...' : cleaned;
      }
    }
    
    return 'Negozio ($ocrSource)';
  }

  DateTime? _extractDate(List<String> lines) {
    // Try yyyy-mm-dd first
    final iso = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})');
    for (final line in lines) {
      final m = iso.firstMatch(line);
      if (m != null) {
        try {
          return DateTime(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
        } catch (_) {}
      }
    }
    
    // Then dd/mm/yyyy or dd-mm-yyyy
    final eu1 = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})');
    final eu2 = RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})');
    for (final line in lines) {
      final m1 = eu1.firstMatch(line) ?? eu2.firstMatch(line);
      if (m1 != null) {
        try {
          final day = int.parse(m1.group(1)!);
          final month = int.parse(m1.group(2)!);
          final year = int.parse(m1.group(3)!);
          if (day <= 31 && month <= 12 && year >= 2020 && year <= DateTime.now().year + 1) {
            return DateTime(year, month, day);
          }
        } catch (_) {}
      }
    }
    
    return null;
  }

  String _suggestCategory(String merchant, List<String> lines) {
    final text = '$merchant ${lines.join(' ')}'.toLowerCase();
    
    if (text.contains('supermercato') || text.contains('market') || text.contains('conad') || text.contains('coop') || text.contains('carrefour')) {
      return 'Spesa';
    } else if (text.contains('carburante') || text.contains('benzina') || text.contains('diesel') || text.contains('eni') || text.contains('agip') || text.contains('shell')) {
      return 'Trasporti';
    } else if (text.contains('ristorante') || text.contains('pizzeria') || text.contains('bar') || text.contains('trattoria') || text.contains('café') || text.contains('caffè')) {
      return 'Svago';
    } else if (text.contains('farmacia') || text.contains('medicina') || text.contains('dottore') || text.contains('ospedale')) {
      return 'Salute';
    } else if (text.contains('abbigliamento') || text.contains('vestiti') || text.contains('scarpe') || text.contains('moda')) {
      return 'Shopping';
    } else if (text.contains('enel') || text.contains('gas') || text.contains('acqua') || text.contains('telefon') || text.contains('internet')) {
      return 'Bollette';
    }
    
    return 'Altro';
  }
}
