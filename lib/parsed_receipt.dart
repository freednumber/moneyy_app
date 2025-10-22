class ParsedReceipt {
  final double amount;
  final String currency;
  final String merchant;
  final DateTime date;
  final String imageUrl;
  final String? categorySuggestion;

  ParsedReceipt({
    required this.amount,
    required this.currency,
    required this.merchant,
    required this.date,
    required this.imageUrl,
    this.categorySuggestion,
  });
}
