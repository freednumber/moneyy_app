import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models.dart';
import 'category_manager_page.dart';

class AddTxPage extends StatefulWidget {
  final bool isIncome;
  final MoneyTx? existingTx;

  const AddTxPage({
    super.key,
    required this.isIncome,
    this.existingTx,
  });

  @override
  State<AddTxPage> createState() => _AddTxPageState();
}

class _AddTxPageState extends State<AddTxPage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedCategory;
  PaymentMethod _selectedPayment = PaymentMethod.carta;
  DateTime _selectedDate = DateTime.now();
  late bool _isIncome;
  
  bool _showAllCategories = false;

  @override
  void initState() {
    super.initState();
    _isIncome = widget.isIncome;

    if (widget.existingTx != null) {
      final tx = widget.existingTx!;
      _amountController.text = tx.amount.toStringAsFixed(2);
      _noteController.text = tx.note ?? '';
      _selectedCategory = tx.category;
      _selectedPayment = tx.payment;
      _selectedDate = tx.date;
      _isIncome = tx.isIncome;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona una categoria')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un importo valido')),
      );
      return;
    }

    final model = Provider.of<MoneyModel>(context, listen: false);
    final tx = MoneyTx(
      id: widget.existingTx?.id,
      isIncome: _isIncome,
      category: _selectedCategory!,
      amount: amount,
      date: _selectedDate,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      payment: _selectedPayment,
    );

    try {
      if (widget.existingTx == null) {
        await model.addTx(tx);
      } else {
        await model.updateTransaction(tx);
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  String _getPaymentLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.contanti:
        return 'Contanti';
      case PaymentMethod.carta:
        return 'Carta';
      case PaymentMethod.bancomat:
        return 'Bancomat';
      case PaymentMethod.bonifico:
        return 'Bonifico';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = Provider.of<MoneyModel>(context);

    final categories = _isIncome
        ? model.allIncomeCats
        : model.allExpenseCats.where((c) => c != 'Altro').toList();

    final visibleCategories = _showAllCategories
        ? categories
        : categories.take(6).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(isDark),
      body: Stack(
        children: [
          // ✅ CONTENUTO SCROLLABILE
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.existingTx == null) _buildToggle(isDark),
                const SizedBox(height: 24),
                _buildAmountField(isDark),
                const SizedBox(height: 24),
                _buildCategorySection(isDark, visibleCategories, categories),
                const SizedBox(height: 24),
                _buildDateField(isDark),
                const SizedBox(height: 24),
                _buildPaymentMethod(isDark),
                const SizedBox(height: 24),
                _buildNoteField(isDark),
              ],
            ),
          ),

          // ✅ BOTTONE IN SOVRIMPRESSIONE
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildSaveButton(isDark),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AppBar(
            title: Text(
              widget.existingTx == null
                  ? 'Nuova Transazione'
                  : 'Modifica Transazione',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
            elevation: 0,
            centerTitle: true,
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.85),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildToggleButton(
            label: 'Uscita',
            icon: Icons.arrow_downward,
            isSelected: !_isIncome,
            color: Colors.red,
            onTap: () => setState(() => _isIncome = false),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildToggleButton(
            label: 'Entrata',
            icon: Icons.arrow_upward,
            isSelected: _isIncome,
            color: Colors.green,
            onTap: () => setState(() => _isIncome = true),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSelected
                    ? [color.withOpacity(0.3), color.withOpacity(0.15)]
                    : [
                        (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                        (isDark ? Colors.white : Colors.black).withOpacity(0.03),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? color.withOpacity(0.5)
                    : (isDark ? Colors.white : Colors.black).withOpacity(0.12),
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? color
                      : (isDark ? Colors.white70 : Colors.black54),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? color
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Importo',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
                ),
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                  suffixText: '€',
                  suffixStyle: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(bool isDark, List<String> visibleCategories, List<String> allCategories) {
    final model = Provider.of<MoneyModel>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoria',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemCount: visibleCategories.length,
          itemBuilder: (context, index) {
            final cat = visibleCategories[index];
            final style = model.getTransactionStyle(cat);
            final isSelected = _selectedCategory == cat;

            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSelected
                            ? [
                                style.color.withOpacity(0.4),
                                style.color.withOpacity(0.25),
                              ]
                            : [
                                (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                                (isDark ? Colors.white : Colors.black).withOpacity(0.03),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? style.color.withOpacity(0.6)
                            : (isDark ? Colors.white : Colors.black).withOpacity(0.12),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          style.icon,
                          color: isSelected
                              ? style.color
                              : (isDark ? Colors.white70 : Colors.black54),
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? style.color
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        if (allCategories.length > 6) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _showAllCategories = !_showAllCategories;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showAllCategories ? Icons.expand_less : Icons.expand_more,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showAllCategories ? 'Mostra meno' : 'Altre categorie...',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryManagerPage(),
      ),
    );
  },
  child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.15),
                  const Color(0xFF6366F1).withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.settings,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Gestisci Categorie',
                  style: TextStyle(
                    color: const Color(0xFF6366F1),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: isDark ? Colors.white70 : Colors.black54,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd MMMM yyyy', 'it').format(_selectedDate),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metodo di pagamento',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final method in PaymentMethod.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildPaymentOption(method, isDark),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentOption(PaymentMethod method, bool isDark) {
    final isSelected = _selectedPayment == method;
    final icons = {
      PaymentMethod.carta: Icons.credit_card,
      PaymentMethod.contanti: Icons.payments,
      PaymentMethod.bancomat: Icons.account_balance_wallet,
      PaymentMethod.bonifico: Icons.account_balance,
    };

    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = method),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSelected
                    ? [
                        const Color(0xFF6366F1).withOpacity(0.3),
                        const Color(0xFF6366F1).withOpacity(0.15),
                      ]
                    : [
                        (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                        (isDark ? Colors.white : Colors.black).withOpacity(0.03),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF6366F1).withOpacity(0.5)
                    : (isDark ? Colors.white : Colors.black).withOpacity(0.12),
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icons[method],
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : (isDark ? Colors.white70 : Colors.black54),
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  _getPaymentLabel(method),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note (opzionale)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
                ),
              ),
              child: TextField(
                controller: _noteController,
                maxLines: 3,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Aggiungi una nota...',
                  hintStyle: TextStyle(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)).withOpacity(0),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: _save,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (_isIncome ? Colors.green : Colors.red).withOpacity(0.8),
                    (_isIncome ? Colors.green : Colors.red).withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isIncome ? Colors.green : Colors.red).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Text(
                'Salva Transazione',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
