import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../parsed_receipt.dart';

/// Servizio OCR gratuito utilizzando OCR.space API
class OCRSpaceService {
  static const String _apiKey = 'K89996646088957';
  static const String _endpoint = 'https://api.ocr.space/parse/image';

  /// Estrae i dati dallo scontrino utilizzando OCR.space
  Future<ParsedReceipt> extractFromImage({
    required String imageUrl,
    required String currencyFallback,
  }) async {
    try {
      if (!imageUrl.startsWith('file://')) {
        throw Exception('Solo file locali supportati');
      }

      final file = File(Uri.parse(imageUrl).toFilePath());
      if (!await file.exists()) {
        throw Exception('File immagine non trovato');
      }

      // Prepara la richiesta multipart
      final request = http.MultipartRequest('POST', Uri.parse(_endpoint));
      
      // Headers
      request.headers['apikey'] = _apiKey;
      
      // Parametri
      request.fields['language'] = 'ita'; // Italiano
      request.fields['isOverlayRequired'] = 'false';
      request.fields['detectOrientation'] = 'true';
      request.fields['scale'] = 'true';
      request.fields['OCREngine'] = '2'; // Motore più recente
      request.fields['isTable'] = 'true'; // Migliora estrazione dati tabulari
      
      // Aggiungi il file
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
      ));

      print('Invio richiesta OCR a OCR.space...');
      
      // Invia richiesta con timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Errore OCR.space: ${response.statusCode} - ${response.body}');
      }

      final data = jsonDecode(response.body);
      
      // Controlla se ci sono errori
      if (data['IsErroredOnProcessing'] == true) {
        final errorMessage = data['ErrorMessage']?.first ?? 'Errore sconosciuto';
        throw Exception('Errore OCR: $errorMessage');
      }

      // Estrai il testo riconosciuto
      final parsedResults = data['ParsedResults'];
      if (parsedResults == null || parsedResults.isEmpty) {
        throw Exception('Nessun testo rilevato nell\'immagine');
      }

      final parsedText = parsedResults[0]['ParsedText'] as String?;
      if (parsedText == null || parsedText.trim().isEmpty) {
        throw Exception('Testo vuoto rilevato');
      }

      print('Testo estratto dall\'OCR:\n$parsedText');

      // Analizza il testo estratto
      return _parseReceiptText(parsedText, imageUrl, currencyFallback);
      
    } catch (e) {
      print('Errore durante l\'estrazione OCR: $e');
      rethrow;
    }
  }

  /// Analizza il testo estratto dall'OCR per identificare i dati dello scontrino
  ParsedReceipt _parseReceiptText(String text, String imageUrl, String currency) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Estrai importo
    double amount = _extractAmount(lines, text);

    // Estrai nome negozio
    String merchant = _extractMerchant(lines);

    // Estrai data
    DateTime date = _extractDate(lines) ?? DateTime.now();

    // Suggerisci categoria
    String category = _suggestCategory(merchant, lines);

    return ParsedReceipt(
      amount: amount,
      currency: currency,
      merchant: merchant,
      date: date,
      imageUrl: imageUrl,
      categorySuggestion: category,
      hasVisionError: false,
    );
  }

  /// Estrae l'importo totale dallo scontrino
  double _extractAmount(List<String> lines, String fullText) {
    final text = fullText.toLowerCase();

    // Pattern prioritari per il totale
    final priorityPatterns = [
      // TOTALE EURO + importo
      RegExp(r'totale\s+euro\s+([0-9]+[,.]\d{2})', caseSensitive: false),
      // TOTALE + importo
      RegExp(r'\btotale\s+([0-9]+[,.]\d{2})', caseSensitive: false),
      // TOTALE COMPLESSIVO
      RegExp(r'totale\s+complessivo\s+([0-9]+[,.]\d{2})', caseSensitive: false),
      // Importo seguito da EUR o €
      RegExp(r'([0-9]+[,.]\d{2})\s*(?:eur|€)', caseSensitive: false),
      // € seguito da importo
      RegExp(r'€\s*([0-9]+[,.]\d{2})'),
    ];

    // Cerca con pattern prioritari
    for (final pattern in priorityPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)!.replaceAll(',', '.');
        final val = double.tryParse(amountStr);
        if (val != null && val > 0 && val < 10000) {
          print('Importo trovato con pattern prioritario: $val');
          return val;
        }
      }
    }

    // Analisi riga per riga
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();

      // Cerca righe con "totale"
      if (line.contains('totale')) {
        final amounts = RegExp(r'([0-9]+[,.]\d{2})').allMatches(line);
        for (final match in amounts) {
          final amountStr = match.group(1)!.replaceAll(',', '.');
          final val = double.tryParse(amountStr);
          if (val != null && val > 0 && val < 10000) {
            print('Importo trovato nella riga TOTALE: $val');
            return val;
          }
        }

        // Controlla la riga successiva
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1];
          final nextAmount = RegExp(r'^([0-9]+[,.]\d{2})').firstMatch(nextLine);
          if (nextAmount != null) {
            final amountStr = nextAmount.group(1)!.replaceAll(',', '.');
            final val = double.tryParse(amountStr);
            if (val != null && val > 0 && val < 10000) {
              print('Importo trovato nella riga dopo TOTALE: $val');
              return val;
            }
          }
        }
      }
    }

    // Fallback: cerca tutti gli importi e prendi il più grande ragionevole
    final allAmounts = <double>[];
    for (final line in lines) {
      final lineLower = line.toLowerCase();

      // Salta righe con codici fiscali, partita IVA, ecc.
      if (lineLower.contains('p.iva') ||
          lineLower.contains('codice') ||
          lineLower.contains('c.f.') ||
          lineLower.contains('tel')) {
        continue;
      }

      final amounts = RegExp(r'([0-9]+[,.]\d{2})').allMatches(line);
      for (final match in amounts) {
        final amountStr = match.group(1)!.replaceAll(',', '.');
        final val = double.tryParse(amountStr);
        if (val != null && val > 0.5 && val < 10000) {
          allAmounts.add(val);
        }
      }
    }

    if (allAmounts.isNotEmpty) {
      allAmounts.sort();
      final largest = allAmounts.last;
      print('Importo trovato con fallback (più grande): $largest');
      return largest;
    }

    print('Nessun importo valido trovato');
    return 0.0;
  }

  /// Estrae il nome del negozio
  String _extractMerchant(List<String> lines) {
    final ignoreWords = {
      'scontrino', 'ricevuta', 'receipt', 'fiscal', 'fiscale',
      'via', 'viale', 'corso', 'piazza', 'tel', 'telefono',
      'p.iva', 'partita', 'iva', 'codice', 'c.f.', 'cf',
      'documento', 'commerciale', 'vendita', 'totale',
      'servizio', 'operatore', 'op',
    };

    // Analizza le prime 10 righe
    for (final line in lines.take(10)) {
      final lower = line.toLowerCase();
      final cleaned = line.trim();

      // Salta righe troppo corte o troppo lunghe
      if (cleaned.length < 3 || cleaned.length > 40) continue;

      // Salta righe con parole da ignorare
      if (ignoreWords.any((w) => lower.contains(w))) continue;

      // Salta righe con principalmente numeri
      if (RegExp(r'^[0-9\s.,:-]+$').hasMatch(cleaned)) continue;

      // Salta righe con prezzi
      if (RegExp(r'\d+[,.]\d{2}\s*€?$').hasMatch(cleaned)) continue;

      // Pulisci e capitalizza
      final merchantName = cleaned
          .replaceAll(RegExp(r'[^\p{L}\p{N}\s&.-]', unicode: true), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (merchantName.length >= 3) {
        // Capitalizza correttamente
        final words = merchantName.split(' ');
        final capitalized = words.map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        }).join(' ');

        return capitalized.length > 35
            ? '${capitalized.substring(0, 35)}...'
            : capitalized;
      }
    }

    return 'Negozio';
  }

  /// Estrae la data dallo scontrino
  DateTime? _extractDate(List<String> lines) {
    final datePatterns = [
      // dd/mm/yyyy
      RegExp(r'(\d{1,2})[/\s-](\d{1,2})[/\s-](\d{4})'),
      // dd-mm-yyyy
      RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})'),
      // dd.mm.yyyy
      RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})'),
      // yyyy-mm-dd
      RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'),
    ];

    for (final line in lines.take(15)) {
      for (int i = 0; i < datePatterns.length; i++) {
        final match = datePatterns[i].firstMatch(line);
        if (match != null) {
          try {
            int day, month, year;

            if (i == 3) {
              // yyyy-mm-dd
              year = int.parse(match.group(1)!);
              month = int.parse(match.group(2)!);
              day = int.parse(match.group(3)!);
            } else {
              // dd/mm/yyyy, dd-mm-yyyy, dd.mm.yyyy
              day = int.parse(match.group(1)!);
              month = int.parse(match.group(2)!);
              year = int.parse(match.group(3)!);
            }

            // Valida la data
            if (day >= 1 &&
                day <= 31 &&
                month >= 1 &&
                month <= 12 &&
                year >= 2020 &&
                year <= DateTime.now().year + 1) {
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

  /// Suggerisce una categoria basata sul contenuto dello scontrino
  String _suggestCategory(String merchant, List<String> lines) {
    final text = '$merchant ${lines.join(' ')}'.toLowerCase();

    if (_containsAny(text, [
      'supermercato', 'market', 'conad', 'coop', 'carrefour',
      'esselunga', 'famila', 'auchan', 'ipercoop', 'spesa',
      'alimentari', 'discount', 'lidl', 'eurospin'
    ])) {
      return 'Spesa';
    }

    if (_containsAny(text, [
      'ristorante', 'pizzeria', 'bar', 'trattoria', 'caffè',
      'pub', 'gelateria', 'pasticceria', 'mcdonald', 'burger',
      'kfc', 'pizza', 'sushi', 'kebab'
    ])) {
      return 'Svago';
    }

    if (_containsAny(text, [
      'carburante', 'benzina', 'diesel', 'eni', 'agip',
      'shell', 'esso', 'q8', 'ip', 'tamoil'
    ])) {
      return 'Trasporti';
    }

    if (_containsAny(text, [
      'farmacia', 'medicina', 'parafarmacia', 'sanitario',
      'medico', 'ospedale'
    ])) {
      return 'Salute';
    }

    if (_containsAny(text, [
      'abbigliamento', 'vestiti', 'scarpe', 'moda',
      'boutique', 'zara', 'h&m'
    ])) {
      return 'Shopping';
    }

    if (_containsAny(text, [
      'enel', 'gas', 'acqua', 'telefon', 'internet',
      'tim', 'vodafone', 'wind', 'fastweb', 'bolletta'
    ])) {
      return 'Bollette';
    }

    return 'Altro';
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }
}
