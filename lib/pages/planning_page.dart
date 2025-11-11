import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../models.dart';
import '../providers.dart';

enum PlanningTab { obiettivi, ricorrenti }

/// Pagina unificata: Obiettivi + Transazioni Ricorrenti
class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key});

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  PlanningTab _selectedTab = PlanningTab.obiettivi;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final model = context.watch<MoneyModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              title: Text(
                'Pianificazione',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              automaticallyImplyLeading: false,
              elevation: 0,
              centerTitle: true,
              backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab selector stile dock
          _buildTabSelector(isDark),
          // Content
          Expanded(
            child: _selectedTab == PlanningTab.obiettivi
                ? _buildGoalsContent(model, isDark)
                : _buildRecurringContent(model, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 58,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.15) : Colors.white,
                width: 1.2,
              ),
            ),
            child: Stack(
              children: [
                // Highlight animato
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: _selectedTab == PlanningTab.obiettivi ? 8 : MediaQuery.of(context).size.width / 2 - 8,
                  top: 4,
                  child: Container(
                    width: MediaQuery.of(context).size.width / 2 - 32,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedTab = PlanningTab.obiettivi);
                        },
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.flag,
                                color: _selectedTab == PlanningTab.obiettivi
                                    ? Colors.white
                                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Obiettivi',
                                style: TextStyle(
                                  color: _selectedTab == PlanningTab.obiettivi
                                      ? Colors.white
                                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                  fontWeight: _selectedTab == PlanningTab.obiettivi ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedTab = PlanningTab.ricorrenti);
                        },
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.repeat,
                                color: _selectedTab == PlanningTab.ricorrenti
                                    ? Colors.white
                                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ricorrenti',
                                style: TextStyle(
                                  color: _selectedTab == PlanningTab.ricorrenti
                                      ? Colors.white
                                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                  fontWeight: _selectedTab == PlanningTab.ricorrenti ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Metodo pubblico per essere chiamato dal FAB
  void showAddDialog(BuildContext context) {
    if (_selectedTab == PlanningTab.obiettivi) {
      final model = Provider.of<MoneyModel>(context, listen: false);
      _showAddGoalDialog(context, model);
    } else {
      _showAddRecurringDialog(context);
    }
  }

  // ========== GOALS CONTENT ==========
  Widget _buildGoalsContent(MoneyModel model, bool isDark) {
    if (model.loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await model.loadInitial();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (model.activeGoals.isNotEmpty) ...[
              Text(
                'In Corso',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ...model.activeGoals.map((goal) => _buildGoalCard(goal, model, false, isDark)),
              const SizedBox(height: 20),
            ],
            if (model.completedGoals.isNotEmpty) ...[
              Text(
                'Completati',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ...model.completedGoals.map((goal) => _buildGoalCard(goal, model, true, isDark)),
            ],
            if (model.goals.isEmpty) _buildGoalsEmptyState(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(Goal goal, MoneyModel model, bool isCompleted, bool isDark) {
    final style = model.getGoalStyle(goal.title);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.15) : Colors.white,
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [style.color, style.color.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(14),
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
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${model.format(goal.saved)} / ${model.format(goal.target)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[300] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted && !goal.isPurchased)
                      ElevatedButton(
                        onPressed: () => _showPurchaseDialog(goal, model),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Salda', style: TextStyle(fontSize: 13)),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: goal.progress / 100,
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(style.color),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: style.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${goal.progress.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : style.color,
                        ),
                      ),
                    ),
                    if (!goal.isPurchased)
                      Text(
                        'Mancano ${model.format(goal.target - goal.saved)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.1 : 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(Icons.flag, size: 50, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Nessun obiettivo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea il tuo primo obiettivo di risparmio',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========== RECURRING CONTENT ==========
  Widget _buildRecurringContent(MoneyModel model, bool isDark) {
    if (model.recurringTransactions.isEmpty) {
      return _buildRecurringEmptyState(isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
      itemCount: model.recurringTransactions.length,
      itemBuilder: (context, index) {
        final recurring = model.recurringTransactions[index];
        return _buildRecurringCard(recurring, model, isDark);
      },
    );
  }

  Widget _buildRecurringCard(Recurring recurring, MoneyModel model, bool isDark) {
    final style = model.getTransactionStyle(recurring.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.15) : Colors.white,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [style.color, style.color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(style.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
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
                      Text(
                        'Giorno ${recurring.dayOfMonth} alle ${recurring.time.format(context)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '- ${model.format(recurring.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFFF6B6B) : Colors.red[700],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecurringEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.1 : 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(Icons.repeat, size: 50, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Nessuna ricorrente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aggiungi bollette e abbonamenti',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========== GOAL DIALOGS ==========
  void _showAddGoalDialog(BuildContext context, MoneyModel model) {
    final targetController = TextEditingController();
    String selectedCategory = model.goalCategories.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withOpacity(0.75) : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(isDark ? 0.2 : 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flag, color: Color(0xFF6366F1)),
                            const SizedBox(width: 8),
                            Text(
                              'Nuovo Obiettivo',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Categoria',
                            prefixIcon: Icon(
                              model.getGoalStyle(selectedCategory).icon,
                              color: model.getGoalStyle(selectedCategory).color,
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                          items: model.goalCategories.map((cat) {
                            final style = model.getGoalStyle(cat);
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
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => selectedCategory = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: targetController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Importo obiettivo (€)',
                            prefixIcon: const Icon(Icons.euro),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            hintText: '500.00',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Annulla'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final target = double.tryParse(targetController.text);
                                  if (target != null && target > 0) {
                                    final goal = Goal(
                                      id: null,
                                      title: selectedCategory,
                                      target: target,
                                      saved: 0,
                                      isPurchased: false,
                                    );
                                    await model.addGoal(goal);
                                    Navigator.pop(dialogContext);
                                    HapticFeedback.heavyImpact();
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✅ Obiettivo creato!'),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.save),
                                label: const Text('Crea'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showPurchaseDialog(Goal goal, MoneyModel model) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.75) : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.2 : 0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Salda Obiettivo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Confermi di voler saldare "${goal.title}"?',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Annulla'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await model.purchaseGoal(goal.id!);
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text('${goal.title} saldato!'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Conferma'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========== RECURRING DIALOGS ==========
  void _showAddRecurringDialog(BuildContext context) {
    final model = Provider.of<MoneyModel>(context, listen: false);
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String? selectedCategory;
    PaymentMethod selectedPayment = PaymentMethod.carta;
    int selectedDay = 1;
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: StatefulBuilder(
          builder: (context, setState) => Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withOpacity(0.75) : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(isDark ? 0.2 : 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.repeat, color: Color(0xFF10B981)),
                            const SizedBox(width: 8),
                            const Text(
                              'Nuova Ricorrente',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Categoria',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          hint: const Text('Seleziona categoria'),
                          dropdownColor: isDark ? Colors.grey[800] : Colors.white,
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
                        DropdownButtonFormField<int>(
                          value: selectedDay,
                          decoration: InputDecoration(
                            labelText: 'Giorno del mese',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                          items: List.generate(28, (i) => i + 1).map((day) {
                            return DropdownMenuItem(
                              value: day,
                              child: Text('Giorno $day'),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => selectedDay = val!),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: noteCtrl,
                          decoration: InputDecoration(
                            labelText: 'Nota (opzionale)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Annulla'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (selectedCategory == null) return;
                                  final amount = double.tryParse(amountCtrl.text);
                                  if (amount == null || amount <= 0) return;

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
                                  HapticFeedback.heavyImpact();
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Ricorrente creata!'),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.save),
                                label: const Text('Salva'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
