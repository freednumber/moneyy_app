import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark 
        ? const Color(0xFF0F172A)
        : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Transazioni Ricorrenti',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
        backgroundColor: isDark 
          ? const Color(0xFF1E293B)
          : Colors.white,
      ),
      body: model.recurringTransactions.isEmpty
          ? _buildEmptyState(isDark)
          : ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
              itemCount: model.recurringTransactions.length,
              itemBuilder: (context, index) {
                final recurring = model.recurringTransactions[index];
                return _buildRecurringCard(recurring, model, isDark);
              },
            ),
    );
  }

  // METODO PUBBLICO per essere chiamato dal FAB globale
  void showAddRecurringDialog(BuildContext context) {
    _showAddRecurringDialog(context);
  }

  Widget _buildEmptyState(bool isDark) {
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
          Text(
            'Nessuna transazione ricorrente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aggiungi spese ricorrenti come bollette e abbonamenti',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringCard(Recurring recurring, MoneyModel model, bool isDark) {
    final style = model.getTransactionStyle(recurring.category);

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
            backgroundColor: isDark ? Colors.grey[900] : Colors.white,
            title: Text(
              'Elimina Ricorrente',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            content: Text(
              'Sei sicuro di voler eliminare questa transazione ricorrente?',
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.black87,
              ),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Annulla',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Elimina', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        model.deleteRecurring(recurring.id!);
        HapticFeedback.mediumImpact();
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
        color: isDark 
          ? Colors.grey[900]!.withOpacity(0.8)
          : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: isDark ? 8 : 2,
        shadowColor: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            _showEditRecurringDialog(context, recurring, model);
          },
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
                        blurRadius: 6,
                        offset: const Offset(0, 3),
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
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Giorno ${recurring.dayOfMonth} del mese',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'alle ${recurring.time.format(context)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (recurring.note != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          recurring.note!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFFF6B6B) : const Color(0xFFEF4444),
                        fontSize: 16,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                          ? style.color.withOpacity(0.2)
                          : style.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        recurring.payment.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : style.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: isDark ? Colors.grey[400] : Colors.grey.shade400,
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    HapticFeedback.mediumImpact(); // Feedback al tap

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.add_circle, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(
                'Nuova Ricorrente',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : null,
                    ),
                  ),
                  hint: Text(
                    'Seleziona categoria',
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ),
                  dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                  items: model.expenseCats.map((cat) {
                    final style = model.getTransactionStyle(cat);
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(style.icon, color: style.color, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            cat,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedCategory = val),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Importo (€)',
                    prefixIcon: const Icon(Icons.euro),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    hintText: '0.00',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : null,
                    ),
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<int>(
                  value: selectedDay,
                  decoration: InputDecoration(
                    labelText: 'Giorno del mese',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : null,
                    ),
                  ),
                  dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                  items: List.generate(28, (i) => i + 1).map((day) {
                    return DropdownMenuItem(
                      value: day,
                      child: Text(
                        'Giorno $day',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedDay = val!),
                ),
                const SizedBox(height: 16),
                
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
                      border: Border.all(
                        color: isDark ? Colors.grey[600]! : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Orario: ${selectedTime.format(context)}',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<PaymentMethod>(
                  value: selectedPayment,
                  decoration: InputDecoration(
                    labelText: 'Metodo di pagamento',
                    prefixIcon: Icon(
                      selectedPayment == PaymentMethod.contanti ? Icons.money :
                      selectedPayment == PaymentMethod.carta ? Icons.credit_card : Icons.account_balance,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : null,
                    ),
                  ),
                  dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                  items: PaymentMethod.values.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Row(
                        children: [
                          Icon(
                            method == PaymentMethod.contanti ? Icons.money :
                            method == PaymentMethod.carta ? Icons.credit_card : Icons.account_balance,
                            size: 20,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            method.name.toUpperCase(),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedPayment = val!),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: noteCtrl,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nota (opzionale)',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    hintText: 'Es: Bolletta luce, Netflix...',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : null,
                    ),
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Annulla',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
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
                
                try {
                  final recurring = Recurring(
                    category: selectedCategory!,
                    amount: amount,
                    dayOfMonth: selectedDay,
                    time: selectedTime,
                    payment: selectedPayment,
                    note: noteCtrl.text.isEmpty ? null : noteCtrl.text.trim(),
                  );
                  
                  await model.addRecurring(recurring);
                  
                  Navigator.pop(dialogContext);
                  HapticFeedback.heavyImpact(); // Feedback al salvataggio
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Ricorrente "$selectedCategory" salvata'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Errore nel salvataggio: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Salva'),
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

  void _showEditRecurringDialog(BuildContext context, Recurring recurring, MoneyModel model) {
    final amountCtrl = TextEditingController(text: recurring.amount.toString());
    final noteCtrl = TextEditingController(text: recurring.note ?? '');
    String selectedCategory = recurring.category;
    PaymentMethod selectedPayment = recurring.payment;
    int selectedDay = recurring.dayOfMonth;
    TimeOfDay selectedTime = recurring.time;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.edit, color: Color(0xFF6366F1)),
              const SizedBox(width: 8),
              Text(
                'Modifica Ricorrente',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: Icon(
                      model.getTransactionStyle(selectedCategory).icon,
                      color: model.getTransactionStyle(selectedCategory).color,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : null,
                    ),
                  ),
                  dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                  items: model.expenseCats.map((cat) {
                    final style = model.getTransactionStyle(cat);
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(style.icon, color: style.color, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            cat,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
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
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Importo (€)',
                    prefixIcon: const Icon(Icons.euro),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<int>(
                  value: selectedDay,
                  decoration: InputDecoration(
                    labelText: 'Giorno del mese',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : null,
                    ),
                  ),
                  dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                  items: List.generate(28, (i) => i + 1).map((day) {
                    return DropdownMenuItem(
                      value: day,
                      child: Text(
                        'Giorno $day',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedDay = val!),
                ),
                const SizedBox(height: 16),
                
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
                      border: Border.all(
                        color: isDark ? Colors.grey[600]! : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Orario: ${selectedTime.format(context)}',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<PaymentMethod>(
                  value: selectedPayment,
                  decoration: InputDecoration(
                    labelText: 'Metodo di pagamento',
                    prefixIcon: Icon(
                      selectedPayment == PaymentMethod.contanti ? Icons.money :
                      selectedPayment == PaymentMethod.carta ? Icons.credit_card : Icons.account_balance,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : null,
                    ),
                  ),
                  dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                  items: PaymentMethod.values.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Row(
                        children: [
                          Icon(
                            method == PaymentMethod.contanti ? Icons.money :
                            method == PaymentMethod.carta ? Icons.credit_card : Icons.account_balance,
                            size: 20,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            method.name.toUpperCase(),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedPayment = val!),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: noteCtrl,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nota (opzionale)',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    hintText: 'Es: Bolletta luce, Netflix...',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : null,
                    ),
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Annulla',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
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
                
                try {
                  final newRecurring = Recurring(
                    category: selectedCategory!,
                    amount: amount,
                    dayOfMonth: selectedDay,
                    time: selectedTime,
                    payment: selectedPayment,
                    note: noteCtrl.text.isEmpty ? null : noteCtrl.text.trim(),
                  );
                  
                  await model.addRecurring(newRecurring);
                  
                  Navigator.pop(dialogContext);
                  HapticFeedback.heavyImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Ricorrente "$selectedCategory" salvata'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Errore nel salvataggio: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Salva'),
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
}