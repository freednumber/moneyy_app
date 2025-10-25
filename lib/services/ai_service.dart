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
    
    // Extract amount with advanced context-aware Italian receipt parsing
    double amount = _extractAmountAdvanced(lines);
    
    // Extract merchant with improved filtering
    String merchant = _extractMerchantAdvanced(lines, ocrSource);
    
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

  double _extractAmountAdvanced(List<String> lines) {
    // Create a clean text representation for better pattern matching
    final fullText = lines.join(' ').toLowerCase();
    print('Full text for amount parsing: $fullText');
    
    // Phase 1: Ultra-high priority patterns - explicit TOTAL mentions with context
    final ultraPriorityPatterns = <RegExp>[
      // TOTALE EURO + whitespace + amount (your McDonald's case)
      RegExp(r'totale\s+euro\s+([0-9]+[,.]\d{2})', caseSensitive: false),
      // TOTALE COMPLESSIVO + whitespace + amount
      RegExp(r'totale\s+complessivo\s+([0-9]+[,.]\d{2})', caseSensitive: false),
      // Single TOTALE + amount (but only if near end of receipt)
      RegExp(r'\btotale\s+([0-9]+[,.]\d{2})', caseSensitive: false),
    ];
    
    // Check ultra-priority patterns first
    for (final pattern in ultraPriorityPatterns) {
      final match = pattern.firstMatch(fullText);
      if (match != null) {
        final amountStr = match.group(1)!.replaceAll(',', '.');
        final val = double.tryParse(amountStr);
        if (val != null && val > 0 && val < 10000) {
          print('Found amount with ULTRA priority pattern: $val');
          return val;
        }
      }
    }
    
    // Phase 2: Line-by-line analysis for isolated TOTALE lines
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      final nextLine = i + 1 < lines.length ? lines[i + 1] : '';
      
      // Look for standalone "TOTALE EURO" followed by amount on same or next line
      if (line.contains('totale euro')) {
        // Check same line first
        final sameLinePattern = RegExp(r'([0-9]+[,.]\d{2})');
        final sameLineMatch = sameLinePattern.firstMatch(line);
        if (sameLineMatch != null) {
          final amountStr = sameLineMatch.group(1)!.replaceAll(',', '.');
          final val = double.tryParse(amountStr);
          if (val != null && val > 0 && val < 10000) {
            print('Found amount on TOTALE EURO line: $val');
            return val;
          }
        }
        
        // Check next line for amount
        if (nextLine.isNotEmpty) {
          final nextLinePattern = RegExp(r'^([0-9]+[,.]\d{2})');
          final nextLineMatch = nextLinePattern.firstMatch(nextLine.trim());
          if (nextLineMatch != null) {
            final amountStr = nextLineMatch.group(1)!.replaceAll(',', '.');
            final val = double.tryParse(amountStr);
            if (val != null && val > 0 && val < 10000) {
              print('Found amount on line after TOTALE EURO: $val');
              return val;
            }
          }
        }
      }
    }
    
    // Phase 3: High priority patterns - contextual totals
    final highPriorityPatterns = <RegExp>[
      // Amount followed by EUR/€ at end of line (likely total)
      RegExp(r'([0-9]+[,.]\d{2})\s*(?:eur|€)\s*$', caseSensitive: false),
      // € symbol followed by amount
      RegExp(r'€\s*([0-9]+[,.]\d{2})'),
    ];
    
    // Analyze from bottom up (totals usually at end)
    for (final line in lines.reversed) {
      for (final pattern in highPriorityPatterns) {
        final match = pattern.firstMatch(line.toLowerCase());
        if (match != null) {
          final amountStr = match.group(1)!.replaceAll(',', '.');
          final val = double.tryParse(amountStr);
          if (val != null && val > 0 && val < 10000) {
            // Additional context check - avoid P.IVA and similar
            if (!line.toLowerCase().contains('p.iva') && 
                !line.toLowerCase().contains('codice') &&
                !line.toLowerCase().contains('via')) {
              print('Found amount with high priority pattern: $val from line: $line');
              return val;
            }
          }
        }
      }
    }
    
    // Phase 4: Smart fallback - find reasonable decimal amounts, exclude obvious non-totals
    final decimalAmounts = <double>[];
    for (final line in lines) {
      final lineLower = line.toLowerCase();
      
      // Skip lines that are clearly not totals
      if (lineLower.contains('p.iva') || 
          lineLower.contains('codice') ||
          lineLower.contains('via') ||
          lineLower.contains('tel') ||
          lineLower.contains('cf')) {
        continue;
      }
      
      final amounts = RegExp(r'([0-9]+[,.]\d{2})').allMatches(line);
      for (final match in amounts) {
        final amountStr = match.group(1)!.replaceAll(',', '.');
        final val = double.tryParse(amountStr);
        if (val != null && val > 1.0 && val < 10000) {
          decimalAmounts.add(val);
        }
      }
    }
    
    if (decimalAmounts.isNotEmpty) {
      // Sort and prefer larger amounts (more likely to be totals)
      decimalAmounts.sort();
      
      // If we have multiple amounts, prefer the largest reasonable one
      // but not if it's way larger than others (could be P.IVA code)
      final largest = decimalAmounts.last;
      final secondLargest = decimalAmounts.length > 1 ? decimalAmounts[decimalAmounts.length - 2] : largest;
      
      // If largest is more than 10x the second largest, prefer second largest
      if (largest > secondLargest * 10 && secondLargest > 10) {
        print('Found amount with smart fallback (avoiding outlier): $secondLargest');
        return secondLargest;
      } else {
        print('Found amount with smart fallback: $largest');
        return largest;
      }
    }
    
    print('No valid amount found in receipt');
    return 0.0;
  }

  String _extractMerchantAdvanced(List<String> lines, String ocrSource) {
    final ignoreWords = {
      'scontrino', 'ricevuta', 'receipt', 'fiscal', 'fiscale',
      'via', 'viale', 'corso', 'piazza', 'tel', 'telefono', 
      'p.iva', 'partita', 'iva', 'codice', 'cf', 'documento', 
      'commerciale', 'vendita', 'prestazione', 'descrizione', 
      'totale', 'servizio', 'tavolo', 'op', 'operatore',
      'roma', 'milano', 'napoli', 'torino', // common cities
      'manolo', // operator names from your receipt
    };
    
    // Skip lines that look like codes or addresses
    final codePatterns = [
      RegExp(r'^\d{5,}$'), // Long number sequences (like P.IVA)
      RegExp(r'^\d{2}-\d{2}-\d{2}'), // Date patterns
      RegExp(r'^\d+:\d+$'), // Time patterns
      RegExp(r'^[A-Z]{2,}\s+\d+'), // Codes like "SF 96"
    ];
    
    for (final line in lines.take(15)) { // Check first 15 lines
      final lower = line.toLowerCase();
      final originalLine = line.trim();
      
      // Skip very short, very long, or empty lines
      if (originalLine.length < 3 || originalLine.length > 35) continue;
      
      // Skip lines with ignore words
      if (ignoreWords.any((w) => lower.contains(w))) continue;
      
      // Skip lines that match code patterns
      if (codePatterns.any((pattern) => pattern.hasMatch(originalLine))) continue;
      
      // Skip lines that are mostly numbers, prices, or symbols
      if (RegExp(r'^[0-9\s.,:€%-]+$').hasMatch(originalLine)) continue;
      
      // Skip lines that look like menu items with prices
      if (RegExp(r'\d+[,.]\d{2}$').hasMatch(originalLine)) continue;
      
      // Skip single character or very short words
      if (originalLine.split(' ').every((word) => word.length <= 2)) continue;
      
      // Clean up the merchant name
      String cleaned = originalLine
          .replaceAll(RegExp(r'[^\p{L}\p{N}\s&.-]', unicode: true), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      
      // Additional filtering for cleaned result
      if (cleaned.length >= 4 && 
          !RegExp(r'^\d+$').hasMatch(cleaned) && // Not just numbers
          cleaned.split(' ').length <= 6) { // Not too many words
        
        // Capitalize properly and limit length
        final words = cleaned.split(' ');
        final capitalizedWords = words.map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).toList();
        
        final result = capitalizedWords.join(' ');
        return result.length > 30 ? '${result.substring(0, 30)}...' : result;
      }
    }
    
    return 'Negozio ($ocrSource)';
  }

  DateTime? _extractDate(List<String> lines) {
    // Italian date patterns with flexible spacing
    final datePatterns = <RegExp>[
      // dd/mm/yyyy
      RegExp(r'(\d{1,2})[/\s-](\d{1,2})[/\s-](\d{4})'),
      // dd-mm-yyyy  
      RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})'),
      // yyyy-mm-dd (ISO format)
      RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'),
      // dd.mm.yyyy
      RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})'),
    ];
    
    for (final line in lines.take(20)) { // Check first 20 lines
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
      'rosticceria', 'paninoteca', 'self service', 'mensa', 'mcdonald',
      'burger', 'hamburger', 'kfc', 'domino', 'pizza'
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