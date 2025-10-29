class ParsedReceipt {
  final double amount;
  final String currency;
  final String merchant;
  final DateTime date;
  final String imageUrl;
  final String? categorySuggestion;
  final bool hasVisionError;

  const ParsedReceipt({
    required this.amount,
    required this.currency,
    required this.merchant,
    required this.date,
    required this.imageUrl,
    this.categorySuggestion,
    this.hasVisionError = false,
  });

  @override
  String toString() {
    return 'ParsedReceipt{amount: $amount, currency: $currency, merchant: $merchant, date: $date, category: $categorySuggestion, hasVisionError: $hasVisionError}';
  }
}
