import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../providers.dart';

class AddTxPage extends StatefulWidget {
  final bool isIncome;
  
  const AddTxPage({super.key, required this.isIncome});
  
  @override
  State<AddTxPage> createState() => _AddTxPageState();
}

class _AddTxPageState extends State<AddTxPage> {
  late bool _isIncome;
  String? _selectedCategory;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  PaymentMethod _selectedPayment = PaymentMethod.contanti;

  @override
  void initState() {
    super.initState();
    _isIncome = widget.isIncome;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<MoneyModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = _isIncome ? model.allIncomeCats : model.allExpenseCats;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        elevation: 0,
        title: Text(
          'Nuova Transazione',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnimatedToggle(isDark),
                const SizedBox(height: 20),
                
                _buildAmountField(isDark),
                const SizedBox(height: 20),
                
                Text(
                  'Categoria',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                
                _buildCategoriesGrid(categories, model, isDark),
                
                if (categories.length > 9)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildAltroButton(categories, model, isDark),
                  ),
                
                const SizedBox(height: 20),
                _buildDateField(isDark),
                const SizedBox(height: 16),
                _buildPaymentMethodField(isDark),
                const SizedBox(height: 16),
                _buildNoteField(isDark),
              ],
            ),
          ),
          
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStickyButton(isDark, model),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedToggle(bool isDark) {
    return Center(
      child: Container(
        width: 280,
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200],
          borderRadius: BorderRadius.circular(25),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: _isIncome ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 140,
                height: 46,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: _isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isIncome = false;
                        _selectedCategory = null;
                      });
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              color: !_isIncome ? Colors.white : (isDark ? Colors.white54 : Colors.grey[600]),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Uscita',
                              style: TextStyle(
                                color: !_isIncome ? Colors.white : (isDark ? Colors.white54 : Colors.grey[600]),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isIncome = true;
                        _selectedCategory = null;
                      });
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              color: _isIncome ? Colors.white : (isDark ? Colors.white54 : Colors.grey[600]),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Entrata',
                              style: TextStyle(
                                color: _isIncome ? Colors.white : (isDark ? Colors.white54 : Colors.grey[600]),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(List<String> categories, MoneyModel model, bool isDark) {
    final displayedCategories = categories.take(9).toList();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemCount: displayedCategories.length,
      itemBuilder: (context, index) {
        final cat = displayedCategories[index];
        final style = model.getTransactionStyle(cat);
        final isSelected = _selectedCategory == cat;
        
        return _buildCategoryCard(
          icon: style.icon,
          label: cat,
          color: style.color,
          isSelected: isSelected,
          isDark: isDark,
          onTap: () {
            setState(() => _selectedCategory = cat);
            HapticFeedback.lightImpact();
          },
          onLongPress: () {
            if (model.customExpenseCats.contains(cat) || model.customIncomeCats.contains(cat)) {
              _showEditCategoryDialog(model, cat, style.icon, style.color, isDark);
            }
          },
        );
      },
    );
  }

  Widget _buildAltroButton(List<String> categories, MoneyModel model, bool isDark) {
    return InkWell(
      onTap: () {
        _showAllCategoriesDialog(categories, model, isDark);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey[400]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.more_horiz, color: isDark ? Colors.white70 : Colors.grey[700], size: 22),
            const SizedBox(width: 8),
            Text(
              'Altre Categorie',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : (isDark ? Colors.white70 : Colors.grey[700]), size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : (isDark ? Colors.white70 : Colors.grey[700]),
              ),
            ),
          ],
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            prefixText: '€ ',
            prefixStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
            hintText: '0.00',
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() => _selectedDate = date);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: isDark ? Colors.white70 : Colors.grey[700]),
                const SizedBox(width: 12),
                Text(
                  DateFormat('d MMMM yyyy', 'it_IT').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metodo di pagamento',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonFormField<PaymentMethod>(
            value: _selectedPayment,
            decoration: const InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(Icons.payment),
            ),
            dropdownColor: isDark ? Colors.grey[800] : Colors.white,
            items: PaymentMethod.values.map((method) {
              return DropdownMenuItem(
                value: method,
                child: Text(
                  method.name.toUpperCase(),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedPayment = val);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoteField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note (opzionale)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          maxLines: 3,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'Aggiungi una nota...',
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.note, color: isDark ? Colors.white70 : Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildStickyButton(bool isDark, MoneyModel model) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: () => _saveTransaction(model),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Salva Transazione',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  void _saveTransaction(MoneyModel model) {
    if (_selectedCategory == null) {
      _showSnackBar('Seleziona una categoria', Colors.red);
      return;
    }
    
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar('Inserisci un importo valido', Colors.red);
      return;
    }
    
    final tx = MoneyTx(
      id: null,
      isIncome: _isIncome,
      category: _selectedCategory!,
      amount: amount,
      date: _selectedDate,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      payment: _selectedPayment,
    );
    
    model.addTx(tx);
    HapticFeedback.heavyImpact();
    Navigator.pop(context);
    _showSnackBar('Transazione salvata!', const Color(0xFF10B981));
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAllCategoriesDialog(List<String> categories, MoneyModel model, bool isDark) {
    final remainingCategories = categories.skip(9).toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          'Tutte le Categorie',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: remainingCategories.length,
                  itemBuilder: (context, index) {
                    final cat = remainingCategories[index];
                    final style = model.getTransactionStyle(cat);
                    final isSelected = _selectedCategory == cat;
                    
                    return _buildCategoryCard(
                      icon: style.icon,
                      label: cat,
                      color: style.color,
                      isSelected: isSelected,
                      isDark: isDark,
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        Navigator.pop(context);
                        HapticFeedback.lightImpact();
                      },
                      onLongPress: () {
                        if (model.customExpenseCats.contains(cat) || model.customIncomeCats.contains(cat)) {
                          Navigator.pop(context);
                          _showEditCategoryDialog(model, cat, style.icon, style.color, isDark);
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Aggiungi Categoria'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showAddCategoryDialog(model, isDark);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(MoneyModel model, bool isDark) {
    final nameController = TextEditingController();
    IconData selectedIcon = Icons.category;
    Color selectedColor = const Color(0xFF6366F1);
    
    final availableIcons = [
      Icons.category, Icons.shopping_bag, Icons.restaurant, Icons.local_cafe,
      Icons.directions_car, Icons.local_gas_station, Icons.flight, Icons.hotel,
      Icons.fitness_center, Icons.sports_soccer, Icons.book, Icons.school,
      Icons.movie, Icons.music_note, Icons.pets, Icons.child_care,
      Icons.medical_services, Icons.local_pharmacy, Icons.spa, Icons.brush,
      Icons.laptop, Icons.phone_android, Icons.headphones, Icons.camera,
      Icons.home, Icons.weekend, Icons.lightbulb, Icons.build,
      Icons.card_giftcard, Icons.celebration, Icons.favorite, Icons.star,
    ];
    
    final availableColors = [
      const Color(0xFF6366F1), const Color(0xFF8B5CF6), const Color(0xFFEC4899),
      const Color(0xFFEF4444), const Color(0xFFF59E0B), const Color(0xFF10B981),
      const Color(0xFF06B6D4), const Color(0xFF3B82F6), const Color(0xFF14B8A6),
      const Color(0xFF84CC16), const Color(0xFFF97316), const Color(0xFF6B7280),
    ];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: Text(
            'Aggiungi Categoria',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Nome categoria',
                      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Text(
                    'Scegli un colore',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: availableColors.map((color) {
                      final isSelected = selectedColor == color;
                      return InkWell(
                        onTap: () {
                          setDialogState(() => selectedColor = color);
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 20),
                  Text(
                    'Scegli un\'icona',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: availableIcons.length,
                      itemBuilder: (context, index) {
                        final icon = availableIcons[index];
                        final isSelected = selectedIcon == icon;
                        return InkWell(
                          onTap: () {
                            setDialogState(() => selectedIcon = icon);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? selectedColor.withOpacity(0.2) : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? selectedColor : Colors.grey,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              icon,
                              color: isSelected ? selectedColor : (isDark ? Colors.white70 : Colors.grey),
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  model.addCustomCategory(name, selectedIcon, _isIncome, selectedColor);
                  setState(() => _selectedCategory = name);
                  Navigator.pop(context);
                  _showSnackBar('Categoria "$name" aggiunta!', const Color(0xFF10B981));
                }
              },
              child: const Text('Aggiungi'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(MoneyModel model, String categoryName, IconData currentIcon, Color currentColor, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          'Modifica "$categoryName"',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          'Vuoi eliminare questa categoria?',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              model.deleteCustomCategory(categoryName, _isIncome);
              if (_selectedCategory == categoryName) {
                setState(() => _selectedCategory = null);
              }
              _showSnackBar('Categoria "$categoryName" eliminata', Colors.red);
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}
