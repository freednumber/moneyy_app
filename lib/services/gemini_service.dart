import 'package:google_generative_ai/google_generative_ai.dart';
import '../models.dart';

class GeminiService {
  // ⚠️ IMPORTANTE: Sostituisci con la TUA chiave API
  static const String API_KEY = 'AIzaSyC...TUA_CHIAVE_QUI';
  
  late final GenerativeModel _model;
  
  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: API_KEY,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
  }
  
  /// Analizza le spese e fornisce consigli personalizzati
  Future<String> analyzeSpending(List<MoneyTx> transactions) async {
    if (transactions.isEmpty) {
      return "📊 Non ci sono abbastanza dati per l'analisi.\n\n"
          "Aggiungi alcune transazioni per ottenere consigli personalizzati!";
    }
    
    try {
      // Calcola statistiche
      final totalSpent = transactions
          .where((tx) => !tx.isIncome)
          .fold(0.0, (sum, tx) => sum + tx.amount);
      
      final totalIncome = transactions
          .where((tx) => tx.isIncome)
          .fold(0.0, (sum, tx) => sum + tx.amount);
      
      final categoryBreakdown = <String, double>{};
      for (var tx in transactions.where((tx) => !tx.isIncome)) {
        categoryBreakdown[tx.category] = (categoryBreakdown[tx.category] ?? 0) + tx.amount;
      }
      
      final topCategories = categoryBreakdown.entries
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final prompt = '''
Sei un consulente finanziario esperto e amichevole. Analizza questi dati e fornisci 3-4 consigli PRATICI e SPECIFICI.

DATI FINANZIARI:
- 💰 Entrate: €${totalIncome.toStringAsFixed(2)}
- 💸 Spese: €${totalSpent.toStringAsFixed(2)}
- 💵 Saldo: €${(totalIncome - totalSpent).toStringAsFixed(2)}

TOP CATEGORIE DI SPESA:
${topCategories.take(5).map((e) => '${e.key}: €${e.value.toStringAsFixed(2)} (${((e.value / totalSpent) * 100).toStringAsFixed(1)}%)').join('\n')}

COMPITO:
Fornisci consigli in formato:
1. [Emoji] Titolo breve
   Spiegazione pratica e specifica

Sii motivante, concreto e usa emoji. Max 200 parole.
''';
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      return response.text ?? '❌ Impossibile generare consigli al momento.';
      
    } catch (e) {
      return '❌ Errore nell\'analisi: ${e.toString()}\n\n'
          'Verifica la connessione internet e la chiave API.';
    }
  }
  
  /// Suggerisce categoria automaticamente
  Future<String> suggestCategory(String description, double amount) async {
    try {
      final prompt = '''
Suggerisci SOLO il nome della categoria per questa transazione:

Descrizione: "$description"
Importo: €$amount

Categorie: Spesa, Trasporti, Ristoranti, Svago, Shopping, Bollette, Casa, Salute, Istruzione, Sport, Viaggi, Altro

Rispondi con UNA SOLA PAROLA (il nome della categoria).
''';
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text?.trim() ?? 'Altro';
      
    } catch (e) {
      return 'Altro';
    }
  }
  
  /// Predice spese future
  Future<String> predictNextMonthExpenses(List<MoneyTx> transactions) async {
    if (transactions.isEmpty) {
      return "📊 Servono più dati storici per fare predizioni accurate.";
    }
    
    try {
      // Calcola medie mensili
      final monthlyData = <String, double>{};
      for (var tx in transactions.where((tx) => !tx.isIncome)) {
        final monthKey = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
        monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + tx.amount;
      }
      
      final prompt = '''
Analizza questi dati storici mensili e prevedi le spese del PROSSIMO MESE:

${monthlyData.entries.map((e) => '${e.key}: €${e.value.toStringAsFixed(2)}').join('\n')}

Fornisci:
1. 💰 Stima realistica per il prossimo mese
2. 📊 Trend identificato
3. 💡 2 suggerimenti specifici

Sii specifico e usa emoji. Max 150 parole.
''';
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      return response.text ?? '❌ Impossibile fare predizioni al momento.';
      
    } catch (e) {
      return '❌ Errore nella predizione: ${e.toString()}';
    }
  }
  
  /// Chat generica con AI
  Future<String> askFinancialQuestion(String question, List<MoneyTx> transactions) async {
    try {
      final totalIncome = transactions
          .where((tx) => tx.isIncome)
          .fold(0.0, (sum, tx) => sum + tx.amount);
      
      final totalExpenses = transactions
          .where((tx) => !tx.isIncome)
          .fold(0.0, (sum, tx) => sum + tx.amount);
      
      final prompt = '''
CONTESTO FINANZIARIO:
- 💰 Entrate totali: €${totalIncome.toStringAsFixed(2)}
- 💸 Spese totali: €${totalExpenses.toStringAsFixed(2)}
- 📊 Transazioni: ${transactions.length}
- 💵 Saldo netto: €${(totalIncome - totalExpenses).toStringAsFixed(2)}

DOMANDA UTENTE:
$question

Rispondi in modo:
- Chiaro e conciso
- Pratico e attuabile
- Con emoji per leggibilità
- Max 200 parole

Fornisci consigli specifici basati sui dati.
''';
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      return response.text ?? '❌ Non ho potuto elaborare la risposta.';
      
    } catch (e) {
      return '❌ Errore: ${e.toString()}\n\nVerifica connessione e API key.';
    }
  }
}
