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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRecurringDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuova Ricorrente'),
        backgroundColor: const Color(0xFF6366F1),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(Icons.repeat, size: 60, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nessuna transazione ricorrente',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Aggiungi spese ricorrenti come bollette e abbonamenti',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddRecurringDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi Prima Ricorrente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
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
          const SnackBar(
            content: Text('Transazione ricorrente eliminata'),
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: isDark ? Colors.white60 : Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            'alle ${recurring.time.format(context)}',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600]),
                          ),
                        ],
                      ),
                      if (recurring.note != null) ...[
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
    String? selectedCategory;
    PaymentMethod selectedPayment = PaymentMethod.carta;
    int selectedDay = 1;
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_circle, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('Nuova Ricorrente'),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // CATEGORIA con icone
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: selectedCategory != null 
                      ? Icon(
                          model.getTransactionStyle(selectedCategory!).icon,
                          color: model.getTransactionStyle(selectedCategory!).color,
                        )
                      : const Icon(Icons.category),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  hint: const Text('Seleziona categoria'),
                  items: model.expenseCats.map((cat) {
                    final style = model.getTransactionStyle(cat);
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(style.icon, color: style.color, size: 20),
                          const SizedBox(width: 12),
                          Text(cat),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedCategory = val),
                ),
                const SizedBox(height: 16),
                
                // IMPORTO
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Importo (€)',
                    prefixIcon: const Icon(Icons.euro),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    hintText: '0.00',
                  ),
                ),
                const SizedBox(height: 16),
                
                // GIORNO DEL MESE
                DropdownButtonFormField<int>(
                  value: selectedDay,
                  decoration: InputDecoration(
                    labelText: 'Giorno del mese',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: List.generate(28, (i) => i + 1).map((day) {
                    return DropdownMenuItem(
                      value: day,
                      child: Text('Giorno $day'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedDay = val!),
                ),
                const SizedBox(height: 16),
                
                // ORARIO
                InkWell(
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
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time),
                        const SizedBox(width: 12),
                        Text('Orario: ${selectedTime.format(context)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // METODO PAGAMENTO  
                DropdownButtonFormField<PaymentMethod>(
                  value: selectedPayment,
                  decoration: InputDecoration(
                    labelText: 'Metodo di pagamento',
                    prefixIcon: Icon(
                      selectedPayment == PaymentMethod.contanti ? Icons.money :
                      selectedPayment == PaymentMethod.carta ? Icons.credit_card : Icons.account_balance,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: PaymentMethod.values.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Row(
                        children: [
                          Icon(
                            method == PaymentMethod.contanti ? Icons.money :
                            method == PaymentMethod.carta ? Icons.credit_card : Icons.account_balance,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Text(method.name.toUpperCase()),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedPayment = val!),
                ),
                const SizedBox(height: 16),
                
                // NOTE
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nota (opzionale)',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    hintText: 'Es: Bolletta luce, Netflix...',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Annulla'),
            ),
            ElevatedButton.icon(
              onPressed: isLoading ? null : () async {
                // VALIDAZIONE ESPLICITA
                if (selectedCategory == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Seleziona una categoria'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                final amount = double.tryParse(amountCtrl.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Inserisci un importo valido'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                setState(() => isLoading = true);
                
                try {
                  final recurring = Recurring(
                    category: selectedCategory!,
                    amount: amount,
                    dayOfMonth: selectedDay,
                    time: selectedTime,
                    payment: selectedPayment,
                    note: noteCtrl.text.isEmpty ? null : noteCtrl.text.trim(),
                  );
                  
                  // SALVATAGGIO CON FEEDBACK
                  await model.addRecurring(recurring);
                  
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Ricorrente "$selectedCategory" salvata'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  setState(() => isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Errore nel salvataggio: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
              label: Text(isLoading ? 'Salvando...' : 'Salva'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringCard(Recurring recurring, MoneyModel model) {
    final style = model.getTransactionStyle(recurring.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
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
                  gradient: LinearGradient(
                    colors: [style.color, style.color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: style.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Ogni ${recurring.dayOfMonth}° del mese',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'alle ${recurring.time.format(context)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    if (recurring.note != null) ...[
                      const SizedBox(height: 4),
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
                    '- €${recurring.amount.toStringAsFixed(2)}',
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
    );
  }

  void _showEditRecurringDialog(BuildContext context, Recurring recurring, MoneyModel model) {
    final amountCtrl = TextEditingController(text: recurring.amount.toString());
    final noteCtrl = TextEditingController(text: recurring.note ?? '');
    String selectedCategory = recurring.category;
    PaymentMethod selectedPayment = recurring.payment;
    int selectedDay = recurring.dayOfMonth;
    TimeOfDay selectedTime = recurring.time;
    bool isLoading = false;

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // CATEGORIA con icone
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: Icon(
                      model.getTransactionStyle(selectedCategory).icon,
                      color: model.getTransactionStyle(selectedCategory).color,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: model.expenseCats.map((cat) {
                    final style = model.getTransactionStyle(cat);
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(style.icon, color: style.color, size: 20),
                          const SizedBox(width: 12),
                          Text(cat),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 16),
                
                // IMPORTO
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Importo (€)',
                    prefixIcon: const Icon(Icons.euro),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                
                // GIORNO
                DropdownButtonFormField<int>(
                  value: selectedDay,
                  decoration: InputDecoration(
                    labelText: 'Giorno del mese',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: List.generate(28, (i) => i + 1).map((day) {
                    return DropdownMenuItem(value: day, child: Text('Giorno $day'));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedDay = val!),
                ),
                const SizedBox(height: 16),
                
                // ORARIO
                InkWell(
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
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time),
                        const SizedBox(width: 12),
                        Text('Orario: ${selectedTime.format(context)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // METODO PAGAMENTO
                DropdownButtonFormField<PaymentMethod>(
                  value: selectedPayment,
                  decoration: InputDecoration(
                    labelText: 'Metodo di pagamento',
                    prefixIcon: Icon(
                      selectedPayment == PaymentMethod.contanti ? Icons.money :
                      selectedPayment == PaymentMethod.carta ? Icons.credit_card : Icons.account_balance,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: PaymentMethod.values.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Row(
                        children: [
                          Icon(
                            method == PaymentMethod.contanti ? Icons.money :
                            method == PaymentMethod.carta ? Icons.credit_card : Icons.account_balance,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Text(method.name.toUpperCase()),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedPayment = val!),
                ),
                const SizedBox(height: 16),
                
                // NOTE
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nota (opzionale)',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Annulla'),
            ),
            ElevatedButton.icon(
              onPressed: isLoading ? null : () async {
                // VALIDAZIONE ESPLICITA
                final amount = double.tryParse(amountCtrl.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Inserisci un importo valido'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                setState(() => isLoading = true);
                
                try {
                  final updated = Recurring(
                    id: recurring.id,
                    category: selectedCategory,
                    amount: amount,
                    dayOfMonth: selectedDay,
                    time: selectedTime,
                    payment: selectedPayment,
                    note: noteCtrl.text.isEmpty ? null : noteCtrl.text.trim(),
                    lastProcessed: recurring.lastProcessed,
                  );
                  
                  // SALVATAGGIO CON FEEDBACK
                  await model.updateRecurring(updated);
                  
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Ricorrente "$selectedCategory" aggiornata'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  setState(() => isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Errore nell\'aggiornamento: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
              label: Text(isLoading ? 'Salvando...' : 'Salva'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}