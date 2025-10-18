// lib/pages/io_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers.dart';

class IOPage extends StatelessWidget {
  const IOPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importa / Esporta'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Importa CSV'),
              onTap: () {
                HapticFeedback.lightImpact();
                // Logica per l'importazione
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('Esporta CSV'),
              onTap: () {
                HapticFeedback.lightImpact();
                _copyTransactionsToClipboard(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyTransactionsToClipboard(BuildContext context) async {
    final model = context.read<MoneyModel>();
    final transactions = model.recent; // o tutte le transazioni
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessuna transazione da esportare')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Data,Categoria,Importo,Nota,Tipo');
    for (final tx in transactions) {
      final type = tx.isIncome ? 'Entrata' : 'Uscita';
      buffer.writeln('${tx.date},"${tx.category}",${tx.amount},"${tx.note ?? ''}",$type');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dati CSV copiati negli appunti')),
    );
  }
}
