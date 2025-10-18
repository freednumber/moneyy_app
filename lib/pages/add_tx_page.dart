import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../providers.dart';

class AddTxPage extends StatefulWidget {
  final bool initialIsIncome; // ✅ Parametro per impostare default

  const AddTxPage({super.key, this.initialIsIncome = false});

  @override
  State<AddTxPage> createState() => _AddTxPageState();
}

class _AddTxPageState extends State<AddTxPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late bool isIncome;
  String? selectedCategory;
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  PaymentMethod selectedPayment = PaymentMethod.contanti;

  @override
  void initState() {
    super.initState();
    isIncome = widget.initialIsIncome; // ✅ Usa il parametro iniziale
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final model = Provider.of<MoneyModel>(context, listen: false);
    
    final categories = isIncome ? model.incomeCats : model.expenseCats;
    
    if (selectedCategory != null && !categories.contains(selectedCategory)) {
      selectedCategory = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuova Transazione'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ TOGGLE ENTRATA/USCITA con testo bianco
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          isIncome = false;
                          selectedCategory = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: !isIncome ? Colors.red : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward,
                                color: !isIncome ? Colors.white : Colors.grey, // ✅ Bianco quando selezionato
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Uscita',
                                style: TextStyle(
                                  color: !isIncome ? Colors.white : Colors.grey, // ✅ Bianco quando selezionato
                                  fontWeight: !isIncome ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          isIncome = true;
                          selectedCategory = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isIncome ? Colors.green : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                color: isIncome ? Colors.white : Colors.grey, // ✅ Bianco quando selezionato
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Entrata',
                                style: TextStyle(
                                  color: isIncome ? Colors.white : Colors.grey, // ✅ Bianco quando selezionato
                                  fontWeight: isIncome ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // CATEGORIA
            const Text('Categoria', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              hint: const Text('Seleziona categoria'),
              items: categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (val) => setState(() => selectedCategory = val),
            ),
            const SizedBox(height: 24),

            // IMPORTO
            const Text('Importo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.euro),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: '0.00',
              ),
            ),
            const SizedBox(height: 24),

            // DATA
            const Text('Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  locale: const Locale('it', 'IT'),
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Text(DateFormat('d MMMM yyyy', 'it_IT').format(selectedDate)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // METODO PAGAMENTO
            const Text('Metodo di pagamento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentMethod>(
              value: selectedPayment,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.payment),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: PaymentMethod.values.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedPayment = val!),
            ),
            const SizedBox(height: 24),

            // NOTE
            const Text('Note (opzionale)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.note),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'Aggiungi una nota...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // PULSANTE SALVA
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  if (selectedCategory == null || amountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Compila tutti i campi obbligatori')),
                    );
                    return;
                  }

                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inserisci un importo valido')),
                    );
                    return;
                  }

                  final tx = MoneyTx(
                    id: null,
                    isIncome: isIncome,
                    category: selectedCategory!,
                    amount: amount,
                    date: selectedDate,
                    note: noteController.text.isEmpty ? null : noteController.text,
                    payment: selectedPayment,
                  );

                  await model.addTx(tx);

                  // Reset form
                  setState(() {
                    selectedCategory = null;
                    amountController.clear();
                    noteController.clear();
                    selectedDate = DateTime.now();
                    selectedPayment = PaymentMethod.contanti;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${isIncome ? "Entrata" : "Uscita"} aggiunta con successo!'),
                      backgroundColor: isIncome ? Colors.green : Colors.red,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isIncome ? Colors.green : Colors.red,
                  foregroundColor: Colors.white, // ✅ Testo sempre bianco
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Salva Transazione', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
