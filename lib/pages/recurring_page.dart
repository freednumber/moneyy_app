import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers.dart';

class RecurringPage extends StatefulWidget {
  const RecurringPage({super.key});

  @override
  State<RecurringPage> createState() => _RecurringPageState();
}

class _RecurringPageState extends State<RecurringPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final model = context.watch<MoneyModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transazioni Ricorrenti'),
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
      ),
      body: model.recurringTransactions.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: model.recurringTransactions.length,
              itemBuilder: (context, index) {
                final recurring = model.recurringTransactions[index];
                return _buildRecurringCard(recurring, model);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecurringDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.repeat, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Nessuna transazione ricorrente', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          const Text('Aggiungi spese ricorrenti come bollette e abbonamenti', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRecurringCard(Recurring recurring, MoneyModel model) {
    final style = model.getTransactionStyle(recurring.category);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(recurring.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Elimina Ricorrente'),
            content: const Text('Sei sicuro di voler eliminare questa transazione ricorrente?'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Elimina'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        model.deleteRecurring(recurring.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transazione ricorrente eliminata'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showEditRecurringDialog(context, recurring, model),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [style.color, style.color.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(style.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recurring.category,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: isDark ? Colors.white60 : Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            'Giorno ${recurring.dayOfMonth} del mese',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600]),
                          ),
                        ],
                      ),
                      // ✅ NUOVO: Mostra l'orario
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: isDark ? Colors.white60 : Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            'alle ${recurring.formattedTime}',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600]),
                          ),
                        ],
                      ),
                      if (recurring.note != null) ..[
                        const SizedBox(height: 2),
                        Text(
                          recurring.note!,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '- ${model.format(recurring.amount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: style.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        recurring.payment.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: style.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddRecurringDialog(BuildContext context) {
    final model = Provider.of<MoneyModel>(context, listen: false);
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String selectedCategory = model.expenseCats.first;
    PaymentMethod selectedPayment = PaymentMethod.carta;
    int selectedDay = 1;
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0); // ✅ NUOVO: Orario predefinito

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuova Ricorrente'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Categoria', prefixIcon: Icon(Icons.category)),
                  items: model.expenseCats.map((cat) {
                    final style = model.getTransactionStyle(cat);
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(style.icon, color: style.color, size: 20),
                          const SizedBox(width: 8),
                          Text(cat),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Importo (€)', prefixIcon: Icon(Icons.euro)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedDay,
                  decoration: const InputDecoration(labelText: 'Giorno del mese', prefixIcon: Icon(Icons.calendar_today)),
                  items: List.generate(28, (i) => i + 1).map((day) {
                    return DropdownMenuItem(value: day, child: Text('Giorno $day'));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedDay = val!),
                ),
                const SizedBox(height: 16),
                // ✅ NUOVO: Time picker
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Orario'),
                  subtitle: Text(selectedTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            timePickerTheme: TimePickerThemeData(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (time != null) {
                      setState(() => selectedTime = time);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentMethod>(
                  value: selectedPayment,
                  decoration: const InputDecoration(labelText: 'Metodo di pagamento', prefixIcon: Icon(Icons.payment)),
                  items: PaymentMethod.values.map((method) {
                    return DropdownMenuItem(value: method, child: Text(method.name.toUpperCase()));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedPayment = val!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'Nota (opzionale)', prefixIcon: Icon(Icons.note)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annulla')),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text);
                if (amount != null && amount > 0) {
                  final recurring = Recurring(
                    category: selectedCategory,
                    amount: amount,
                    dayOfMonth: selectedDay,
                    time: selectedTime, // ✅ NUOVO
                    payment: selectedPayment,
                    note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                  );
                  model.addRecurring(recurring);
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transazione ricorrente aggiunta'), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('Aggiungi'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRecurringDialog(BuildContext context, Recurring recurring, MoneyModel model) {
    final amountCtrl = TextEditingController(text: recurring.amount.toString());
    final noteCtrl = TextEditingController(text: recurring.note ?? '');
    String selectedCategory = recurring.category;
    PaymentMethod selectedPayment = recurring.payment;
    int selectedDay = recurring.dayOfMonth;
    TimeOfDay selectedTime = recurring.time; // ✅ NUOVO

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, color: Color(0xFF6366F1)),
              SizedBox(width: 8),
              Text('Modifica Ricorrente'),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Categoria', prefixIcon: Icon(Icons.category)),
                  items: model.expenseCats.map((cat) {
                    final style = model.getTransactionStyle(cat);
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(style.icon, color: style.color, size: 20),
                          const SizedBox(width: 8),
                          Text(cat),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Importo (€)', prefixIcon: Icon(Icons.euro)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedDay,
                  decoration: const InputDecoration(labelText: 'Giorno del mese', prefixIcon: Icon(Icons.calendar_today)),
                  items: List.generate(28, (i) => i + 1).map((day) {
                    return DropdownMenuItem(value: day, child: Text('Giorno $day'));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedDay = val!),
                ),
                const SizedBox(height: 16),
                // ✅ NUOVO: Time picker per modifica
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Orario'),
                  subtitle: Text(selectedTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            timePickerTheme: TimePickerThemeData(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (time != null) {
                      setState(() => selectedTime = time);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentMethod>(
                  value: selectedPayment,
                  decoration: const InputDecoration(labelText: 'Metodo di pagamento', prefixIcon: Icon(Icons.payment)),
                  items: PaymentMethod.values.map((method) {
                    return DropdownMenuItem(value: method, child: Text(method.name.toUpperCase()));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedPayment = val!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'Nota (opzionale)', prefixIcon: Icon(Icons.note)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annulla')),
            ElevatedButton.icon(
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text);
                if (amount != null && amount > 0) {
                  final updated = Recurring(
                    id: recurring.id,
                    category: selectedCategory,
                    amount: amount,
                    dayOfMonth: selectedDay,
                    time: selectedTime, // ✅ NUOVO
                    payment: selectedPayment,
                    note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                    lastProcessed: recurring.lastProcessed,
                  );
                  model.updateRecurring(updated);
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transazione ricorrente aggiornata'), backgroundColor: Colors.green),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}
