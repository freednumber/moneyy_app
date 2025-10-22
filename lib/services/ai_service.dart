import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../parsed_receipt.dart';

class AIService {
  static const String _visionEndpoint = 'https://vision.googleapis.com/v1/images:annotate';

  Future<ParsedReceipt> extractFromImage({
    required String imageUrl,
    required String currencyFallback,
  }) async {
    try {
      // If imageUrl is local file, read and encode
      String base64Image;
      if (imageUrl.startsWith('file://')) {
        final file = File(Uri.parse(imageUrl).toFilePath());
        final bytes = await file.readAsBytes();
        base64Image = base64Encode(bytes);
      } else {
        throw Exception('Only local files supported for now');
      }

      final response = await http.post(
        Uri.parse('$_visionEndpoint?key=${ApiKeys.googleVisionApiKey}'),
        headers: {'Content-Type': 'application/json'},
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
      );

      if (response.statusCode != 200) {
        throw Exception('Vision API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final textAnnotations = data['responses']?[0]?['textAnnotations'];
      
      if (textAnnotations == null || textAnnotations.isEmpty) {
        throw Exception('No text detected in image');
      }

      final fullText = textAnnotations[0]['description'] as String;
      return _parseReceiptText(fullText, imageUrl, currencyFallback);
      
    } catch (e) {
      // Fallback with mock data for development
      return ParsedReceipt(
        amount: 0.0,
        currency: currencyFallback,
        merchant: 'OCR Error: $e',
        date: DateTime.now(),
        imageUrl: imageUrl,
        categorySuggestion: 'Altro',
      );
    }
  }

  ParsedReceipt _parseReceiptText(String text, String imageUrl, String currency) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    
    // Extract amount
    double amount = _extractAmount(lines, currency);
    
    // Extract merchant (first non-numeric line, usually at top)
    String merchant = _extractMerchant(lines);
    
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
    );
  }

  double _extractAmount(List<String> lines, String currency) {
    final patterns = [
      RegExp(r'total[e]?[:\s]+([0-9]+[,.]?[0-9]*)', RegExp.caseSensitive),
      RegExp(r'totale[:\s]+([0-9]+[,.]?[0-9]*)', RegExp.caseSensitive),
      RegExp(r'€\s*([0-9]+[,.]?[0-9]*)', RegExp.caseSensitive),
      RegExp(r'([0-9]+[,.]?[0-9]*)\s*€', RegExp.caseSensitive),
      RegExp(r'([0-9]+[,.]?[0-9]*)\s*eur', RegExp.caseSensitive),
    ];
    
    for (final line in lines.reversed) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line.toLowerCase());
        if (match != null) {
          final amountStr = match.group(1)!.replaceAll(',', '.');
          return double.tryParse(amountStr) ?? 0.0;
        }
      }
    }
    
    // Fallback: find largest number in text
    final numbers = RegExp(r'([0-9]+[,.]?[0-9]*)')
        .allMatches(lines.join(' '))
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 0.0)
        .where((n) => n > 0)
        .toList();
    
    return numbers.isNotEmpty ? numbers.reduce((a, b) => a > b ? a : b) : 0.0;
  }

  String _extractMerchant(List<String> lines) {
    final ignoreWords = {'scontrino', 'ricevuta', 'receipt', 'fiscal', 'via', 'tel', 'p.iva'};
    
    for (final line in lines.take(5)) {
      final words = line.toLowerCase().split(' ');
      if (words.any((w) => ignoreWords.contains(w))) continue;
      if (line.length < 3 || line.length > 30) continue;
      if (RegExp(r'^[0-9]+').hasMatch(line)) continue;
      
      return line.length > 20 ? '${line.substring(0, 17)}...' : line;
    }
    
    return 'Negozio sconosciuto';
  }

  DateTime? _extractDate(List<String> lines) {
    final patterns = [
      RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})'), // dd/mm/yyyy
      RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})'), // dd-mm-yyyy
      RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'), // yyyy-mm-dd
    ];
    
    for (final line in lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          try {
            if (pattern == patterns[2]) {
              // yyyy-mm-dd format
              return DateTime(
                int.parse(match.group(1)!),
                int.parse(match.group(2)!),
                int.parse(match.group(3)!),
              );
            } else {
              // dd/mm/yyyy or dd-mm-yyyy
              return DateTime(
                int.parse(match.group(3)!),
                int.parse(match.group(2)!),
                int.parse(match.group(1)!),
              );
            }
          } catch (_) {}
        }
      }
    }
    
    return null;
  }

  String _suggestCategory(String merchant, List<String> lines) {
    final text = '$merchant ${lines.join(' ')}'.toLowerCase();
    
    if (text.contains('supermercato') || text.contains('market') || text.contains('conad') || text.contains('coop')) {
      return 'Spesa';
    } else if (text.contains('carburante') || text.contains('benzina') || text.contains('diesel') || text.contains('eni') || text.contains('agip')) {
      return 'Trasporti';
    } else if (text.contains('ristorante') || text.contains('pizzeria') || text.contains('bar') || text.contains('trattoria')) {
      return 'Ristoranti';
    } else if (text.contains('farmacia') || text.contains('medicina') || text.contains('dottore')) {
      return 'Salute';
    } else if (text.contains('abbigliamento') || text.contains('vestiti') || text.contains('scarpe')) {
      return 'Abbigliamento';
    }
    
    return 'Altro';
  }
}
