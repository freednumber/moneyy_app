import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../parsed_receipt.dart';

class AIService {
  static const String _visionEndpoint = 'https://vision.googleapis.com/v1/images:annotate';
  late final TextRecognizer _textRecognizer;
  
  // Use environment variable or fallback to default for development
  static const String _apiKey = String.fromEnvironment(
    'GOOGLE_VISION_API_KEY',
    defaultValue: 'AIzaSyCI2MJIB_D9b90lMdVUT4GHOu7UsOIZluM', // Your key as fallback
  );

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
      Uri.parse('$_visionEndpoint?key=$_apiKey'),
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
    
    // Extract amount with improved Italian receipt parsing
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
    // Priority patterns for Italian receipts - most specific first
    final priorityPatterns = <RegExp>[
      // TOTALE EURO followed by amount
      RegExp(r'totale\s+euro\s+([0-9]+[,.]\d{2})', caseSensitive: false),
      // TOTALE COMPLESSIVO followed by amount  
      RegExp(r'totale\s+complessivo\s+([0-9]+[,.]\d{2})', caseSensitive: false),
      // Just TOTALE followed by amount
      RegExp(r'totale\s+([0-9]+[,.]\d{2})', caseSensitive: false),
      // TOTALE with optional colon/space followed by amount
      RegExp(r'totale[:\s]+([0-9]+[,.]\d{2})', caseSensitive: false),
    ];
    
    // Secondary patterns for common formats
    final secondaryPatterns = <RegExp>[
      // Amount followed by EUR/€
      RegExp(r'([0-9]+[,.]?\d{0,2})\s*(?:eur|€)', caseSensitive: false),
      // € symbol followed by amount
      RegExp(r'€\s*([0-9]+[,.]\d{2})', caseSensitive: false),
    ];
    
    // First try priority patterns - look for specific TOTALE mentions
    for (final line in lines) {
      for (final pattern in priorityPatterns) {
        final match = pattern.firstMatch(line.toLowerCase());
        if (match != null) {
          final amountStr = match.group(1)!.replaceAll(',', '.');
          final val = double.tryParse(amountStr);
          if (val != null && val > 0 && val < 10000) { // Reasonable receipt amounts
            print('Found amount with priority pattern: $val from line: $line');
            return val;
          }
        }
      }
    }
    
    // If no priority pattern found, try secondary patterns
    for (final line in lines.reversed) { // Start from bottom for totals
      for (final pattern in secondaryPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final amountStr = match.group(1)!.replaceAll(',', '.');
          final val = double.tryParse(amountStr);
          if (val != null && val > 0 && val < 10000) {
            print('Found amount with secondary pattern: $val from line: $line');
            return val;
          }
        }
      }
    }
    
    // Final fallback: find largest reasonable decimal number in text
    final decimalNumbers = RegExp(r'([0-9]+[,.]\d{2})')
        .allMatches(lines.join(' '))
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 0.0)
        .where((n) => n > 1.0 && n < 10000) // Reasonable receipt amounts
        .toList();
    
    if (decimalNumbers.isNotEmpty) {
      // Sort and take the largest reasonable amount
      decimalNumbers.sort();
      final largest = decimalNumbers.last;
      print('Found amount with fallback pattern: $largest');
      return largest;
    }
    
    print('No valid amount found in receipt');
    return 0.0;
  }

  String _extractMerchant(List<String> lines, String ocrSource) {
    final ignoreWords = {
      'scontrino', 'ricevuta', 'receipt', 'fiscal', 'fiscale',
      'via', 'tel', 'telefono', 'p.iva', 'partita', 'iva', 
      'codice', 'cf', 'documento', 'commerciale', 'vendita',
      'prestazione', 'descrizione', 'totale'
    };
    
    for (final line in lines.take(10)) { // Check first 10 lines for merchant
      final lower = line.toLowerCase();
      
      // Skip lines with ignore words
      if (ignoreWords.any((w) => lower.contains(w))) continue;
      
      // Skip very short or very long lines
      if (line.length < 3 || line.length > 40) continue;
      
      // Skip lines that are mostly numbers, prices, or symbols
      if (RegExp(r'^[0-9\s.,€%-]+$').hasMatch(line)) continue;
      
      // Skip lines that look like addresses (contain numbers and short words)
      if (RegExp(r'\b\d+\b.*\b\w{1,3}\b').hasMatch(line)) continue;
      
      // Clean up the merchant name
      final cleaned = line
          .replaceAll(RegExp(r'[^a-zA-Z\u00c0-\u00ff0-9\s&]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
          
      if (cleaned.length >= 3) {
        return cleaned.length > 30 ? '${cleaned.substring(0, 30)}...' : cleaned;
      }
    }
    
    return 'Negozio ($ocrSource)';
  }

  DateTime? _extractDate(List<String> lines) {
    // Italian date patterns
    final datePatterns = <RegExp>[
      // dd/mm/yyyy
      RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})'),
      // dd-mm-yyyy  
      RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})'),
      // yyyy-mm-dd (ISO format)
      RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'),
      // dd.mm.yyyy
      RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})'),
    ];
    
    for (final line in lines.take(15)) { // Check first 15 lines
      for (int i = 0; i < datePatterns.length; i++) {
        final match = datePatterns[i].firstMatch(line);
        if (match != null) {
          try {
            int day, month, year;
            
            if (i == 2) { // yyyy-mm-dd format
              year = int.parse(match.group(1)!);
              month = int.parse(match.group(2)!);
              day = int.parse(match.group(3)!);
            } else { // dd/mm/yyyy, dd-mm-yyyy, dd.mm.yyyy formats
              day = int.parse(match.group(1)!);
              month = int.parse(match.group(2)!);
              year = int.parse(match.group(3)!);
            }
            
            // Validate date components
            if (day >= 1 && day <= 31 && 
                month >= 1 && month <= 12 && 
                year >= 2020 && year <= DateTime.now().year + 1) {
              return DateTime(year, month, day);
            }
          } catch (_) {
            continue;
          }
        }
      }
    }
    
    return null;
  }

  String _suggestCategory(String merchant, List<String> lines) {
    final text = '$merchant ${lines.join(' ')}'.toLowerCase();
    
    // More comprehensive Italian category matching
    if (_containsAnyOf(text, [
      'supermercato', 'market', 'conad', 'coop', 'carrefour', 'esselunga',
      'famila', 'auchan', 'ipercoop', 'ipermercato', 'spesa', 'alimentari'
    ])) {
      return 'Spesa';
    } else if (_containsAnyOf(text, [
      'carburante', 'benzina', 'diesel', 'eni', 'agip', 'shell', 'esso',
      'tamoil', 'ip', 'q8', 'autolavaggio'
    ])) {
      return 'Trasporti';
    } else if (_containsAnyOf(text, [
      'ristorante', 'pizzeria', 'bar', 'trattoria', 'osteria', 'tavola',
      'café', 'caffè', 'pub', 'birreria', 'gelateria', 'pasticceria',
      'rosticceria', 'paninoteca', 'self service', 'mensa'
    ])) {
      return 'Svago';
    } else if (_containsAnyOf(text, [
      'farmacia', 'medicina', 'dottore', 'medico', 'ospedale', 'clinica',
      'dentista', 'veterinario', 'parafarmacia', 'sanitario'
    ])) {
      return 'Salute';
    } else if (_containsAnyOf(text, [
      'abbigliamento', 'vestiti', 'scarpe', 'moda', 'boutique',
      'calzature', 'intimo', 'sportivo', 'accessori'
    ])) {
      return 'Shopping';
    } else if (_containsAnyOf(text, [
      'enel', 'gas', 'acqua', 'telefon', 'internet', 'tim', 'vodafone',
      'wind', 'tre', 'fastweb', 'utenza', 'bolletta'
    ])) {
      return 'Bollette';
    } else if (_containsAnyOf(text, [
      'trasporto', 'autobus', 'metro', 'treno', 'taxi', 'uber',
      'parcheggio', 'autostrada', 'pedaggio', 'biglietto'
    ])) {
      return 'Trasporti';
    }
    
    return 'Altro';
  }

  bool _containsAnyOf(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
}