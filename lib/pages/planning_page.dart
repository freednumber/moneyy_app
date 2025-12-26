import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../models.dart';
import '../providers.dart';

enum PlanningTab { obiettivi, ricorrenti }

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
          _buildTabSelector(isDark),
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
                                Icons.savings_outlined,
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

  void showAddDialog(BuildContext context) {
    if (_selectedTab == PlanningTab.obiettivi) {
      final model = Provider.of<MoneyModel>(context, listen: false);
      _showAddGoalDialog(context, model);
    } else {
      _showAddRecurringDialog(context);
    }
  }

  Widget _buildGoalsContent(MoneyModel model, bool isDark) {
    if (model.loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }

    final activeGoals = model.goals.where((g) => g.progress < 100).toList();
    final completedGoals = model.goals.where((g) => g.progress >= 100).toList();

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
            if (activeGoals.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.savings_outlined, color: Color(0xFF6366F1), size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'In Corso',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...activeGoals.map((goal) => _buildGoalCard(goal, model, false, isDark)),
              const SizedBox(height: 20),
            ],
            if (completedGoals.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.savings, color: Color(0xFF10B981), size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Completati',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...completedGoals.map((goal) => _buildGoalCard(goal, model, true, isDark)),
            ],
            if (model.goals.isEmpty) _buildGoalsEmptyState(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(Goal goal, MoneyModel model, bool isCompleted, bool isDark) {
    final style = model.getGoalStyle(goal.title);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _showGoalOptionsDialog(goal, model, isDark);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
                            colors: isCompleted
                                ? [const Color(0xFF10B981), const Color(0xFF10B981).withOpacity(0.8)]
                                : [style.color, style.color.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: (isCompleted ? const Color(0xFF10B981) : style.color).withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
  child: isCompleted
    ? const Icon(Icons.savings, color: Colors.white, size: 24)
    : Icon(
        goal.icon ?? style.icon,
        color: Colors.white,
        size: 24,
      ),
),  // ← Chiude Center
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
                      valueColor: AlwaysStoppedAnimation(isCompleted ? const Color(0xFF10B981) : style.color),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? const Color(0xFF10B981).withOpacity(0.15)
                              : style.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isCompleted) const Text('✅ ', style: TextStyle(fontSize: 10)),
                            Text(
                              '${goal.progress.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isCompleted
                                    ? const Color(0xFF10B981)
                                    : (isDark ? Colors.white : style.color),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isCompleted)
                        Text(
                          'Mancano ${model.format(goal.target - goal.saved)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        )
                      else
                        const Text(
                          '🎉 Raggiunto!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
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
    );
  }

  void _showGoalOptionsDialog(Goal goal, MoneyModel model, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          goal.title,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Obiettivo di risparmio',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '€ ${goal.saved.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
                Text(
                  ' / € ${goal.target.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: goal.progress / 100,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
            ),
            const SizedBox(height: 8),
            Text(
              '${goal.progress.toStringAsFixed(1)}% completato',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
          if (!goal.isPurchased) ...[
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: isDark ? Colors.grey[900] : Colors.white,
                    title: Text(
                      'Elimina Obiettivo',
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    ),
                    content: Text(
                      'Sei sicuro di voler eliminare "${goal.title}"?',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700]),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annulla'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Elimina'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && goal.id != null) {
                  await model.deleteGoal(goal.id!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Obiettivo eliminato'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Elimina', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _showAddMoneyToGoalDialog(goal, model, isDark);
              },
              child: const Text('Aggiungi Denaro'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _showEditGoalDialog(goal, model, isDark);
              },
              child: const Text('Modifica'),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddMoneyToGoalDialog(Goal goal, MoneyModel model, bool isDark) {
    final controller = TextEditingController();
    final remaining = goal.target - goal.saved;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          'Aggiungi a "${goal.title}"',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mancano ancora €${remaining.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'Importo (max €${remaining.toStringAsFixed(2)})',
                prefixText: '€ ',
                labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Inserisci un importo valido'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              if (amount > remaining) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('⚠️ Puoi aggiungere max €${remaining.toStringAsFixed(2)}'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              await model.addMoneyToGoal(goal, amount);
              if (context.mounted) {
                Navigator.pop(context);
                HapticFeedback.heavyImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('€${amount.toStringAsFixed(2)} aggiunti a ${goal.title}!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  void _showEditGoalDialog(Goal goal, MoneyModel model, bool isDark) {
    final nameController = TextEditingController(text: goal.title);
    final targetController = TextEditingController(text: goal.target.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          'Modifica Obiettivo',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Nome obiettivo',
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Importo target',
                  prefixText: '€ ',
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              final target = double.tryParse(targetController.text);

              if (name.isNotEmpty && target != null && target > 0) {
                final updatedGoal = goal.copyWith(
                  title: name,
                  target: target,
                );
                await model.updateGoal(updatedGoal);
                if (context.mounted) {
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Obiettivo aggiornato!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              }
            },
            child: const Text('Salva'),
          ),
        ],
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
                    child: const Icon(Icons.savings_outlined, size: 50, color: Color(0xFF6366F1)),
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

  Widget _buildRecurringContent(MoneyModel model, bool isDark) {
    if (model.loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }

    if (model.recurringTransactions.isEmpty) {
      return _buildRecurringEmptyState(isDark);
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await model.loadInitial();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: model.recurringTransactions.length,
        itemBuilder: (context, index) {
          final recurring = model.recurringTransactions[index];
          return _buildRecurringCard(recurring, model, isDark);
        },
      ),
    );
  }

  Widget _buildRecurringCard(Recurring recurring, MoneyModel model, bool isDark) {
    final style = model.getTransactionStyle(recurring.category);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _showRecurringOptionsDialog(recurring, model, isDark);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
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
                    child: Icon(style.icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recurring.category,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Giorno ${recurring.dayOfMonth} alle ${recurring.time.hour.toString().padLeft(2, '0')}:${recurring.time.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${recurring.isIncome ? '+' : '-'} ${recurring.amount.toStringAsFixed(2)} €',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: recurring.isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
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
                    'Aggiungi transazioni che si ripetono ogni mese',
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

  void _showRecurringOptionsDialog(Recurring recurring, MoneyModel model, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          recurring.category,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${recurring.isIncome ? 'Entrata' : 'Uscita'} ricorrente',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '€ ${recurring.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: recurring.isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Giorno ${recurring.dayOfMonth} di ogni mese',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Ore ${recurring.time.hour.toString().padLeft(2, '0')}:${recurring.time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              ],
            ),
            if (recurring.note != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.note,
                    size: 16,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recurring.note!,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: isDark ? Colors.grey[900] : Colors.white,
                  title: Text(
                    'Elimina Ricorrente',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
                  content: Text(
                    'Sei sicuro di voler eliminare questa transazione ricorrente?',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700]),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annulla'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Elimina'),
                    ),
                  ],
                ),
              );
              if (confirm == true && recurring.id != null) {
                await model.deleteRecurring(recurring.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transazione ricorrente eliminata'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _showEditRecurringDialog(recurring, model, isDark);
            },
            child: const Text('Modifica'),
          ),
        ],
      ),
    );
  }

  void _showEditRecurringDialog(Recurring recurring, MoneyModel model, bool isDark) {
    final amountController = TextEditingController(text: recurring.amount.toStringAsFixed(2));
    final noteController = TextEditingController(text: recurring.note ?? '');
    int selectedDay = recurring.dayOfMonth;
    TimeOfDay selectedTime = recurring.time;
    PaymentMethod selectedPayment = recurring.payment;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: Text(
            'Modifica ${recurring.category}',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Importo',
                    prefixText: '€ ',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedDay,
                  decoration: InputDecoration(
                    labelText: 'Giorno del mese',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                  ),
                  dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                  items: List.generate(28, (i) => i + 1).map((day) {
                    return DropdownMenuItem(
                      value: day,
                      child: Text(
                        'Giorno $day',
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedDay = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Ora: ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentMethod>(
                  value: selectedPayment,
                  decoration: InputDecoration(
                    labelText: 'Metodo di pagamento',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
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
                      setDialogState(() => selectedPayment = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Note (opzionale)',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Inserisci un importo valido'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final updated = Recurring(
                  id: recurring.id,
                  isIncome: recurring.isIncome,
                  category: recurring.category,
                  amount: amount,
                  dayOfMonth: selectedDay,
                  time: selectedTime,
                  payment: selectedPayment,
                  note: noteController.text.isEmpty ? null : noteController.text,
                  lastProcessed: recurring.lastProcessed,
                );
                await model.updateRecurring(updated);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transazione ricorrente aggiornata!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPurchaseDialog(Goal goal, MoneyModel model) {
    String? selectedCategory;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: Text(
            'Salda Obiettivo',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stai per saldare "${goal.title}"',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Importo:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      '€${goal.target.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Scegli la categoria per la transazione:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Categoria',
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                items: model.allExpenseCats.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(
                      cat,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => selectedCategory = val);
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Verrà creata una transazione e sottratta dal saldo netto',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              onPressed: selectedCategory == null
                  ? null
                  : () async {
                      try {
                        await model.purchaseGoal(goal.id!, selectedCategory!);
                        if (context.mounted) {
                          Navigator.pop(context);
                          HapticFeedback.heavyImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Obiettivo "${goal.title}" saldato!'),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('⚠️ ${e.toString().replaceAll('Exception: ', '')}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Salda Obiettivo'),
            ),
          ],
        ),
      ),
    );
  }

  // ✨ NUOVO METODO CON GLASSMORPHISM E SELEZIONE ICONE
  void _showAddGoalDialog(BuildContext context, MoneyModel model) {
  final titleController = TextEditingController();
  final targetController = TextEditingController();
  IconData selectedIcon = Icons.savings_outlined;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final List<IconData> availableIcons = [
    Icons.savings_outlined,
    Icons.home,
    Icons.flight,
    Icons.directions_car,
    Icons.computer,
    Icons.phone_iphone,
    Icons.watch,
    Icons.shopping_bag,
    Icons.cake,
    Icons.celebration,
    Icons.beach_access,
    Icons.favorite,
    Icons.school,
    Icons.medical_services,
    Icons.sports_esports,
    Icons.music_note,
    Icons.camera_alt,
    Icons.pets,
    Icons.restaurant,
    Icons.fitness_center,
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.black.withOpacity(0.85), Colors.black.withOpacity(0.75)]
                    : [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.85)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.2,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Nuovo Obiettivo di Risparmio',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildGlassField(
                    isDark: isDark,
                    child: TextField(
                      controller: titleController,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Titolo',
                        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                        prefixIcon: Icon(
                          Icons.edit,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildGlassField(
                    isDark: isDark,
                    child: TextField(
                      controller: targetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Obiettivo (€)',
                        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                        prefixIcon: Icon(
                          Icons.euro,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'Scegli un\'icona',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  _buildGlassField(
                    isDark: isDark,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: availableIcons.map((icon) {
                          final isSelected = icon == selectedIcon;
                          return InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setDialogState(() => selectedIcon = icon);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                      )
                                    : null,
                                color: isSelected
                                    ? null
                                    : (isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF6366F1)
                                      : (isDark
                                          ? Colors.white.withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.3)),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF6366F1).withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                icon,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.grey[700]),
                                size: 28,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _buildGlassButton(
                          isDark: isDark,
                          label: 'Annulla',
                          color: Colors.grey,
                          onTap: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildGlassButton(
                          isDark: isDark,
                          label: 'Crea Obiettivo',
                          color: const Color(0xFF6366F1),
                          onTap: () async {
                            final title = titleController.text.trim();
                            final target = double.tryParse(targetController.text);
                            
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('⚠️ Inserisci un titolo'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            
                            if (target == null || target <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('⚠️ Inserisci un importo valido'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            final goal = Goal(
                              title: title,
                              target: target,
                              saved: 0,
                              icon: selectedIcon,
                            );
                            await model.addGoal(goal);
                            if (context.mounted) {
                              Navigator.pop(context);
                              HapticFeedback.heavyImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ Obiettivo "$title" creato!'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            }
                          },
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


  void _showAddRecurringDialog(BuildContext context) {
    final model = Provider.of<MoneyModel>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    bool isIncome = false;
    String selectedCategory = model.expenseCats.first;
    int selectedDay = DateTime.now().day;
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    PaymentMethod selectedPayment = PaymentMethod.carta;
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.black.withOpacity(0.85), Colors.black.withOpacity(0.75)]
                      : [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.85)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.2,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Nuova Transazione Ricorrente',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.15) : Colors.white,
                          width: 1.2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            left: isIncome ? MediaQuery.of(context).size.width / 2 - 8 : 8,
                            top: 4,
                            child: Container(
                              width: MediaQuery.of(context).size.width / 2 - 36,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isIncome
                                      ? [const Color(0xFF10B981), const Color(0xFF10B981).withOpacity(0.8)]
                                      : [const Color(0xFFEF4444), const Color(0xFFEF4444).withOpacity(0.8)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                        .withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setDialogState(() {
                                      isIncome = false;
                                      selectedCategory = model.expenseCats.first;
                                    });
                                  },
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.arrow_downward,
                                          color: !isIncome
                                              ? Colors.white
                                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Uscita',
                                          style: TextStyle(
                                            color: !isIncome
                                                ? Colors.white
                                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                            fontWeight: !isIncome ? FontWeight.w700 : FontWeight.w500,
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
                                    setDialogState(() {
                                      isIncome = true;
                                      selectedCategory = model.incomeCats.first;
                                    });
                                  },
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.arrow_upward,
                                          color: isIncome
                                              ? Colors.white
                                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Entrata',
                                          style: TextStyle(
                                            color: isIncome
                                                ? Colors.white
                                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                            fontWeight: isIncome ? FontWeight.w700 : FontWeight.w500,
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
                    const SizedBox(height: 20),
                    _buildGlassField(
                      isDark: isDark,
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Categoria',
                          labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          prefixIcon: Icon(
                            Icons.category,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                        items: (isIncome ? model.allIncomeCats : model.allExpenseCats).map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(
                              cat,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedCategory = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildGlassField(
                      isDark: isDark,
                      child: TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Importo',
                          labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                          prefixIcon: Icon(
                            Icons.euro,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGlassField(
                            isDark: isDark,
                            child: DropdownButtonFormField<int>(
                              value: selectedDay,
                              decoration: InputDecoration(
                                labelText: 'Giorno',
                                labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                prefixIcon: Icon(
                                  Icons.calendar_today,
                                  color: isDark ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                              dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                              items: List.generate(28, (i) => i + 1).map((day) {
                                return DropdownMenuItem(
                                  value: day,
                                  child: Text(
                                    '$day',
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedDay = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGlassField(
                            isDark: isDark,
                            child: InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                );
                                if (time != null) {
                                  setDialogState(() => selectedTime = time);
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Ora',
                                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  prefixIcon: Icon(
                                    Icons.access_time,
                                    color: isDark ? Colors.white70 : Colors.grey[600],
                                  ),
                                ),
                                child: Text(
                                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildGlassField(
                      isDark: isDark,
                      child: DropdownButtonFormField<PaymentMethod>(
                        value: selectedPayment,
                        decoration: InputDecoration(
                          labelText: 'Metodo di pagamento',
                          labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          prefixIcon: Icon(
                            Icons.payment,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
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
                          if (val != null) setDialogState(() => selectedPayment = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildGlassField(
                      isDark: isDark,
                      child: TextField(
                        controller: noteController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Note (opzionale)',
                          labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                          prefixIcon: Icon(
                            Icons.note_alt,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGlassButton(
                            isDark: isDark,
                            label: 'Annulla',
                            color: Colors.grey,
                            onTap: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildGlassButton(
                            isDark: isDark,
                            label: 'Salva Ricorrente',
                            color: const Color(0xFF6366F1),
                            onTap: () async {
                              final amount = double.tryParse(amountController.text);
                              if (amount == null || amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('⚠️ Inserisci un importo valido'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              final recurring = Recurring(
                                isIncome: isIncome,
                                category: selectedCategory,
                                amount: amount,
                                dayOfMonth: selectedDay,
                                time: selectedTime,
                                payment: selectedPayment,
                                note: noteController.text.isEmpty ? null : noteController.text,
                              );
                              await model.addRecurring(recurring);
                              if (context.mounted) {
                                Navigator.pop(context);
                                HapticFeedback.heavyImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Transazione ricorrente creata!'),
                                    backgroundColor: Color(0xFF10B981),
                                  ),
                                );
                              }
                            },
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

  Widget _buildGlassField({
    required bool isDark,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.15) : Colors.white,
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required bool isDark,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.8),
                  color.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
