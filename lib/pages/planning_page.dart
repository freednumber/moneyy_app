import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

import '../providers/wallet_provider.dart';
import '../providers/category_provider.dart';
import '../models/models.dart';
import '../models/transaction_model.dart';

enum PlanningTab { obiettivi, ricorrenti }

class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key});

  @override
  State<PlanningPage> createState() => PlanningPageState();
}

class PlanningPageState extends State<PlanningPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  PlanningTab _selectedTab = PlanningTab.obiettivi;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final wallet = context.watch<WalletProvider>();
    final catProvider = context.watch<CategoryProvider>();
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
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.85),
              // ❌ RIMOSSO TASTO + DALLA APPBAR
            ),
          ),
        ),
      ),
      // ❌ RIMOSSO FLOATING ACTION BUTTON (Usa quello globale della Shell)
      body: Column(
        children: [
          _buildTabSelector(isDark),
          Expanded(
            child: _selectedTab == PlanningTab.obiettivi
                ? _buildGoalsContent(wallet, catProvider, isDark)
                : _buildRecurringContent(wallet, catProvider, isDark),
          ),
        ],
      ),
    );
  }

  // --- SELETTORE TAB ---
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
                  left: _selectedTab == PlanningTab.obiettivi ? 8 : MediaQuery.of(context).size.width / 2 - 24,
                  right: _selectedTab == PlanningTab.obiettivi ? MediaQuery.of(context).size.width / 2 - 24 : 8,
                  top: 4,
                  bottom: 4,
                  child: Container(
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
                              Icon(Icons.savings_outlined, color: _selectedTab == PlanningTab.obiettivi ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]), size: 20),
                              const SizedBox(width: 8),
                              Text('Obiettivi', style: TextStyle(color: _selectedTab == PlanningTab.obiettivi ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]), fontWeight: _selectedTab == PlanningTab.obiettivi ? FontWeight.w700 : FontWeight.w500, fontSize: 15)),
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
                              Icon(Icons.repeat, color: _selectedTab == PlanningTab.ricorrenti ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]), size: 20),
                              const SizedBox(width: 8),
                              Text('Ricorrenti', style: TextStyle(color: _selectedTab == PlanningTab.ricorrenti ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]), fontWeight: _selectedTab == PlanningTab.ricorrenti ? FontWeight.w700 : FontWeight.w500, fontSize: 15)),
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

  // ---------------------------------------------------------------------------
  // 🎯 OBIETTIVI UI
  // ---------------------------------------------------------------------------
  Widget _buildGoalsContent(WalletProvider wallet, CategoryProvider catProvider, bool isDark) {
    if (wallet.loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }
    
    if (wallet.goals.isEmpty) {
      return Center(
        child: _buildEmptyStateCard(
          isDark: isDark,
          icon: Icons.flag_rounded,
          title: "Nessun Obiettivo",
          description: "Risparmia per i tuoi sogni.\n\nTocca il '+' in basso a destra per creare il tuo primo obiettivo.",
        ),
      );
    }

    final activeGoals = wallet.activeGoals;
    final completedGoals = wallet.completedGoals;

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await wallet.loadInitial();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activeGoals.isNotEmpty) ...[
              Row(children: [const Icon(Icons.savings_outlined, color: Color(0xFF6366F1), size: 24), const SizedBox(width: 10), Text('In Corso', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))]),
              const SizedBox(height: 12),
              ...activeGoals.map((goal) => _buildGoalCard(goal, wallet, catProvider, false, isDark)),
              const SizedBox(height: 20),
            ],
            if (completedGoals.isNotEmpty) ...[
              Row(children: [const Icon(Icons.savings, color: Color(0xFF10B981), size: 24), const SizedBox(width: 10), Text('Completati', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))]),
              const SizedBox(height: 12),
              ...completedGoals.map((goal) => _buildGoalCard(goal, wallet, catProvider, true, isDark)),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🔄 RICORRENTI UI
  // ---------------------------------------------------------------------------
  Widget _buildRecurringContent(WalletProvider wallet, CategoryProvider catProvider, bool isDark) {
    if (wallet.loading) return const Center(child: CircularProgressIndicator());
    
    if (wallet.recurringTransactions.isEmpty) {
      return Center(
        child: _buildEmptyStateCard(
          isDark: isDark,
          icon: Icons.update,
          title: "Nessuna Ricorrenza",
          description: "Gestisci qui le tue spese fisse.\n\nTocca il tasto '+' per iniziare.",
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
      itemCount: wallet.recurringTransactions.length,
      itemBuilder: (context, index) {
        final recurring = wallet.recurringTransactions[index];
        return _buildRecurringCard(recurring, wallet, catProvider, isDark);
      }
    );
  }

  Widget _buildEmptyStateCard({required bool isDark, required IconData icon, required String title, required String description}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: const Color(0xFF6366F1)),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B)
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white60 : Colors.grey[600],
              height: 1.5
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGICA DI ELIMINAZIONE ---
  void _confirmDeleteGoal(Goal goal, BuildContext context, bool isDark) {
    _showGlassDialog(
      context: context,
      title: 'Elimina Obiettivo',
      content: Text('Sei sicuro di voler eliminare "${goal.title}"? Questa azione è irreversibile.', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
      actions: [
        _buildGlassButton(isDark: isDark, label: 'Annulla', color: Colors.grey, onTap: () => Navigator.pop(context)),
        _buildGlassButton(
          isDark: isDark,
          label: 'Elimina',
          color: Colors.red,
          onTap: () async {
            Navigator.pop(context);
            final wallet = Provider.of<WalletProvider>(context, listen: false);
            if (goal.id != null) {
              await wallet.deleteGoal(goal.id!);
            }
          }
        ),
      ],
    );
  }

  void _confirmDeleteRecurring(Recurring recurring, BuildContext context, bool isDark) {
    _showGlassDialog(
      context: context,
      title: 'Elimina Ricorrenza',
      content: Text('Sei sicuro? Non verranno create nuove transazioni automatiche.', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
      actions: [
        _buildGlassButton(isDark: isDark, label: 'Annulla', color: Colors.grey, onTap: () => Navigator.pop(context)),
        _buildGlassButton(
          isDark: isDark,
          label: 'Elimina',
          color: Colors.red,
          onTap: () async {
            Navigator.pop(context);
            final wallet = Provider.of<WalletProvider>(context, listen: false);
            if (recurring.id != null) {
              await wallet.deleteRecurring(recurring.id!);
            }
          }
        ),
      ],
    );
  }

  // --- CARDS ---
  Widget _buildGoalCard(Goal goal, WalletProvider wallet, CategoryProvider catProvider, bool isCompletedParam, bool isDark) {
    final style = catProvider.getGoalStyle(goal.title);
    final iconaMostrata = goal.icon ?? style.icon;
    
    final bool isActuallyCompleted = goal.saved >= goal.target;
    final bool showSettleButton = isActuallyCompleted && !goal.isPurchased;
    
    final gradientColors = isActuallyCompleted
        ? [const Color(0xFF10B981), const Color(0xFF10B981).withOpacity(0.8)]
        : [style.color, style.color.withOpacity(0.8)];

    return InkWell(
      onTap: () { HapticFeedback.lightImpact(); _showGoalOptionsDialog(goal, wallet, isDark); },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.white.withOpacity(0.15) : Colors.white, width: 1.2)),
              child: Column(
                children: [
                  Row(children: [
                    Container(width: 50, height: 50, decoration: BoxDecoration(gradient: LinearGradient(colors: gradientColors), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: gradientColors[0].withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))]), child: Center(child: Icon(iconaMostrata, color: Colors.white, size: 24))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(goal.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)), const SizedBox(height: 4), Text('${wallet.format(goal.saved)} / ${wallet.format(goal.target)}', style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[600]))])),
                    if (showSettleButton) _buildGlassButton(isDark: isDark, label: 'Salda', color: const Color(0xFF10B981), onTap: () => _showPurchaseDialog(goal, wallet), compact: true),
                  ]),
                  const SizedBox(height: 14),
                  ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: (goal.progress / 100).clamp(0.0, 1.0), minHeight: 8, backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200], valueColor: AlwaysStoppedAnimation(isActuallyCompleted ? const Color(0xFF10B981) : style.color))),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isActuallyCompleted ? const Color(0xFF10B981).withOpacity(0.15) : style.color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Text('${goal.progress.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActuallyCompleted ? const Color(0xFF10B981) : (isDark ? Colors.white : style.color)))),
                    if (!isActuallyCompleted)
                      Text('Mancano ${wallet.format(goal.target - goal.saved)}', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]))
                    else
                      const Text('🎉 Raggiunto!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecurringCard(Recurring recurring, WalletProvider wallet, CategoryProvider catProvider, bool isDark) {
    final style = catProvider.getTransactionStyle(recurring.category);
    return InkWell(
      onTap: () => _showRecurringOptionsDialog(recurring, wallet, isDark),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.white.withOpacity(0.15) : Colors.white)),
        child: Row(
          children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: style.color.withOpacity(0.2), borderRadius: BorderRadius.circular(14)), child: Icon(style.icon, color: style.color, size: 28)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(recurring.category, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)), Text('Giorno ${recurring.dayOfMonth} - ${recurring.time.format(context)}', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600]))])),
            Text('${recurring.isIncome ? '+' : '-'} ${wallet.format(recurring.amount)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: recurring.isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
          ],
        ),
      ),
    );
  }

  // --- DIALOGHI ---
  void _showGoalOptionsDialog(Goal goal, WalletProvider wallet, bool isDark) {
    final bool canSettle = goal.saved >= goal.target;
    
    _showGlassDialog(
      context: context,
      title: goal.title,
      content: Column(
        children: [
          _buildInfoRow('Risparmiato:', wallet.format(goal.saved), isDark, color: const Color(0xFF10B981)),
          const SizedBox(height: 8),
          _buildInfoRow('Obiettivo:', wallet.format(goal.target), isDark),
          const SizedBox(height: 24),
          if (!goal.isPurchased) ...[
            _buildGlassButton(isDark: isDark, label: 'Aggiungi Denaro', color: const Color(0xFF10B981), onTap: () { Navigator.pop(context); _showAddMoneyToGoalDialog(goal, wallet, isDark); }),
            const SizedBox(height: 12),
            if (canSettle) ...[
              _buildGlassButton(isDark: isDark, label: 'Salda Obiettivo', color: const Color(0xFF6366F1), onTap: () { Navigator.pop(context); _showPurchaseDialog(goal, wallet); }),
              const SizedBox(height: 12),
            ],
          ],
          Row(
            children: [
              Expanded(child: _buildGlassButton(isDark: isDark, label: 'Modifica', color: const Color(0xFF6366F1), onTap: () { Navigator.pop(context); _showEditGoalSheet(context, wallet, goal); })),
              const SizedBox(width: 12),
              Expanded(child: _buildGlassButton(isDark: isDark, label: 'Elimina', color: const Color(0xFFEF4444), isOutlined: true, onTap: () { Navigator.pop(context); _confirmDeleteGoal(goal, context, isDark); })),
            ],
          ),
        ],
      ),
    );
  }

  void _showRecurringOptionsDialog(Recurring recurring, WalletProvider wallet, bool isDark) {
    _showGlassDialog(
      context: context,
      title: recurring.category,
      content: Column(
        children: [
          _buildInfoRow('Importo:', wallet.format(recurring.amount), isDark, color: recurring.isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
          const SizedBox(height: 8),
          _buildInfoRow('Quando:', 'Giorno ${recurring.dayOfMonth} alle ${recurring.time.format(context)}', isDark),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildGlassButton(isDark: isDark, label: 'Modifica', color: const Color(0xFF6366F1), onTap: () { Navigator.pop(context); _showEditRecurringSheet(context, wallet, recurring); })),
              const SizedBox(width: 12),
              Expanded(child: _buildGlassButton(isDark: isDark, label: 'Elimina', color: const Color(0xFFEF4444), isOutlined: true, onTap: () { Navigator.pop(context); _confirmDeleteRecurring(recurring, context, isDark); })),
            ],
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(Goal goal, WalletProvider wallet) {
    String? selectedCategory;
    final catProvider = Provider.of<CategoryProvider>(context, listen: false);
    final expenseCats = catProvider.allExpenseCats;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _showGlassDialog(
      context: context,
      title: 'Salda ${goal.title}',
      content: Column(
        children: [
          const Text('Scegli la categoria per registrare la spesa:'),
          const SizedBox(height: 16),
          _buildGlassField(
            isDark: isDark,
            child: DropdownButtonFormField<String>(
              value: selectedCategory,
              hint: Text('Seleziona...', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              decoration: _noBorderDecoration('Categoria', Icons.category, isDark),
              items: expenseCats.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: isDark ? Colors.white : Colors.black87)))).toList(),
              onChanged: (v) => selectedCategory = v,
            ),
          ),
        ],
      ),
      actions: [
        _buildGlassButton(isDark: isDark, label: 'Annulla', color: Colors.grey, onTap: () => Navigator.pop(context)),
        _buildGlassButton(isDark: isDark, label: 'Conferma', color: const Color(0xFF10B981), onTap: () async { if (selectedCategory != null) { await wallet.purchaseGoal(goal.id!, selectedCategory!); if (context.mounted) Navigator.pop(context); } }),
      ],
    );
  }

  void _showAddMoneyToGoalDialog(Goal goal, WalletProvider wallet, bool isDark) {
    final controller = TextEditingController();
    final remaining = goal.target - goal.saved;

    _showGlassDialog(
      context: context,
      title: 'Aggiungi a "${goal.title}"',
      content: Column(
        children: [
          Text('Mancano ${wallet.format(remaining)}', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
          const SizedBox(height: 16),
          _buildGlassField(
            isDark: isDark,
            child: TextField(
              controller: controller,
              // Fix virgola
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: _noBorderDecoration('Importo', Icons.euro, isDark),
              autofocus: true,
            ),
          ),
        ],
      ),
      actions: [
        _buildGlassButton(isDark: isDark, label: 'Annulla', color: Colors.grey, onTap: () => Navigator.pop(context)),
        _buildGlassButton(
          isDark: isDark,
          label: 'Aggiungi',
          color: const Color(0xFF10B981),
          onTap: () async {
            // Fix virgola
            final amount = double.tryParse(controller.text.replaceAll(',', '.'));
            
            if (amount == null || amount <= 0) return;
            
            if (amount > remaining) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('L\'importo supera il necessario (${wallet.format(remaining)})'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
              return;
            }

            await wallet.addMoneyToGoal(goal, amount);
            if (mounted) Navigator.pop(context);
          }
        ),
      ],
    );
  }

  // --- SHEET DI MODIFICA ---
  void _showEditGoalSheet(BuildContext context, WalletProvider wallet, Goal? existingGoal) {
    final isEditing = existingGoal != null;
    final titleController = TextEditingController(text: existingGoal?.title ?? '');
    final targetController = TextEditingController(text: existingGoal?.target.toString().replaceAll('.', ',') ?? '');
    IconData selectedIcon = existingGoal?.icon ?? Icons.savings_outlined;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<IconData> availableIcons = [
      Icons.savings_outlined, Icons.home, Icons.flight, Icons.directions_car, Icons.computer, Icons.phone_iphone, Icons.watch, Icons.shopping_bag, Icons.cake, Icons.celebration, Icons.beach_access, Icons.favorite, Icons.school, Icons.medical_services, Icons.sports_esports, Icons.music_note, Icons.camera_alt, Icons.pets, Icons.restaurant, Icons.fitness_center,
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
                gradient: LinearGradient(colors: isDark ? [Colors.black.withOpacity(0.85), Colors.black.withOpacity(0.75)] : [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.85)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 20, right: 20, top: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 42, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.45), borderRadius: BorderRadius.circular(2.5))),
                    const SizedBox(height: 20),
                    Text(isEditing ? 'Modifica Obiettivo' : 'Nuovo Obiettivo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 24),
                    _buildGlassField(isDark: isDark, child: TextField(controller: titleController, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16), decoration: _noBorderDecoration('Titolo', Icons.edit, isDark))),
                    const SizedBox(height: 16),
                    _buildGlassField(isDark: isDark, child: TextField(controller: targetController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16), decoration: _noBorderDecoration('Obiettivo (€)', Icons.euro, isDark))),
                    const SizedBox(height: 20),
                    Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(left: 4, bottom: 12), child: Text('Scegli un\'icona', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)))),
                    _buildGlassField(
                      isDark: isDark,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 12, runSpacing: 12,
                          children: availableIcons.map((icon) {
                            final isSelected = icon == selectedIcon;
                            return InkWell(
                              onTap: () { HapticFeedback.selectionClick(); setDialogState(() => selectedIcon = icon); },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 56, height: 56,
                                decoration: BoxDecoration(
                                  gradient: isSelected ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]) : null,
                                  color: isSelected ? null : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isSelected ? const Color(0xFF6366F1) : Colors.transparent, width: isSelected ? 2 : 1),
                                ),
                                child: Icon(icon, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[700]), size: 28),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(child: _buildGlassButton(isDark: isDark, label: 'Annulla', color: Colors.grey, onTap: () => Navigator.pop(context))),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: _buildGlassButton(isDark: isDark, label: isEditing ? 'Salva Modifiche' : 'Crea Obiettivo', color: const Color(0xFF6366F1), onTap: () async {
                        final title = titleController.text.trim();
                        // Fix virgola
                        final target = double.tryParse(targetController.text.replaceAll(',', '.'));
                        if (title.isEmpty) return;
                        if (target == null || target <= 0) return;
                        if (isEditing) {
                          await wallet.updateGoal(existingGoal!.copyWith(title: title, target: target, icon: selectedIcon));
                        } else {
                          await wallet.addGoal(Goal(title: title, target: target, saved: 0, icon: selectedIcon));
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                          HapticFeedback.heavyImpact();
                        }
                      }))
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ LOGICA DATA INTELLIGENTE
  DateTime? _calculateInitialLastProcessed(int dayOfMonth, TimeOfDay time) {
    final now = DateTime.now();
    
    // 1. Giorno passato nel mese corrente -> Salta al prossimo
    if (dayOfMonth < now.day) {
      return now;
    }
    
    // 2. Giorno futuro nel mese corrente -> Parte questo mese (quindi non processato)
    if (dayOfMonth > now.day) {
      return null;
    }
    
    // 3. Stesso giorno -> Controlla orario
    final nowMinutes = now.hour * 60 + now.minute;
    final selectedMinutes = time.hour * 60 + time.minute;

    if (selectedMinutes < nowMinutes) {
       // Orario passato -> Consideralo già processato questo mese (salta al prossimo)
       return now;
    } else {
       // Orario futuro/uguale -> Parte oggi (non ancora processato)
       return null;
    }
  }

  void _showEditRecurringSheet(BuildContext context, WalletProvider wallet, Recurring? existingRecurring) {
    final catProvider = Provider.of<CategoryProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = existingRecurring != null;

    bool isIncome = existingRecurring?.isIncome ?? false;
    String selectedCategory = existingRecurring?.category ?? catProvider.allExpenseCats.first;
    int selectedDay = existingRecurring?.dayOfMonth ?? DateTime.now().day;
    TimeOfDay selectedTime = existingRecurring?.time ?? const TimeOfDay(hour: 9, minute: 0);
    PaymentMethod selectedPayment = existingRecurring?.payment ?? PaymentMethod.carta;
    final amountController = TextEditingController(text: existingRecurring?.amount.toString().replaceAll('.', ',') ?? '');
    final noteController = TextEditingController(text: existingRecurring?.note ?? '');

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
              decoration: BoxDecoration(gradient: LinearGradient(colors: isDark ? [Colors.black.withOpacity(0.85), Colors.black.withOpacity(0.75)] : [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.85)], begin: Alignment.topCenter, end: Alignment.bottomCenter), border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2), borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 20, right: 20, top: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 42, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.45), borderRadius: BorderRadius.circular(2.5))),
                    const SizedBox(height: 20),
                    Text(isEditing ? 'Modifica Ricorrenza' : 'Nuova Ricorrenza', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 24),
                    Container(
                      height: 58,
                      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white.withOpacity(0.15) : Colors.white, width: 1.2)),
                      child: Row(children: [
                        Expanded(child: InkWell(onTap: () => setDialogState(() { isIncome = false; selectedCategory = catProvider.allExpenseCats.first; }), child: Container(decoration: BoxDecoration(color: !isIncome ? const Color(0xFFEF4444).withOpacity(0.2) : null, borderRadius: BorderRadius.circular(16)), alignment: Alignment.center, child: Text('Uscita', style: TextStyle(color: !isIncome ? Colors.red : Colors.grey))))),
                        Expanded(child: InkWell(onTap: () => setDialogState(() { isIncome = true; selectedCategory = catProvider.allIncomeCats.first; }), child: Container(decoration: BoxDecoration(color: isIncome ? const Color(0xFF10B981).withOpacity(0.2) : null, borderRadius: BorderRadius.circular(16)), alignment: Alignment.center, child: Text('Entrata', style: TextStyle(color: isIncome ? Colors.green : Colors.grey))))),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    _buildGlassField(isDark: isDark, child: DropdownButtonFormField<String>(value: selectedCategory, items: (isIncome ? catProvider.allIncomeCats : catProvider.allExpenseCats).map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: TextStyle(color: isDark ? Colors.white : Colors.black87)))).toList(), onChanged: (val) { if (val != null) setDialogState(() => selectedCategory = val); }, decoration: _noBorderDecoration('Categoria', Icons.category, isDark))),
                    const SizedBox(height: 16),
                    _buildGlassField(isDark: isDark, child: TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _noBorderDecoration('Importo', Icons.euro, isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _buildGlassField(isDark: isDark, child: DropdownButtonFormField<int>(value: selectedDay, items: List.generate(28, (i) => i + 1).map((d) => DropdownMenuItem(value: d, child: Text('$d', style: TextStyle(color: isDark ? Colors.white : Colors.black87)))).toList(), onChanged: (v) { if (v != null) setDialogState(() => selectedDay = v); }, decoration: _noBorderDecoration('Giorno', Icons.calendar_today, isDark)))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildGlassField(isDark: isDark, child: InkWell(onTap: () async { final time = await showTimePicker(context: context, initialTime: selectedTime); if (time != null) setDialogState(() => selectedTime = time); }, child: InputDecorator(decoration: _noBorderDecoration('Ora', Icons.access_time, isDark), child: Text('${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}', style: TextStyle(color: isDark ? Colors.white : Colors.black87))))))
                    ]),
                    const SizedBox(height: 16),
                    _buildGlassField(isDark: isDark, child: DropdownButtonFormField<PaymentMethod>(value: selectedPayment, items: PaymentMethod.values.map((method) => DropdownMenuItem(value: method, child: Text(method.name.toUpperCase(), style: TextStyle(color: isDark ? Colors.white : Colors.black87)))).toList(), onChanged: (val) { if (val != null) setDialogState(() => selectedPayment = val); }, decoration: _noBorderDecoration('Metodo', Icons.payment, isDark))),
                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(child: _buildGlassButton(isDark: isDark, label: 'Annulla', color: Colors.grey, onTap: () => Navigator.pop(context))),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: _buildGlassButton(isDark: isDark, label: isEditing ? 'Salva Modifiche' : 'Salva', color: const Color(0xFF6366F1), onTap: () async {
                        // Fix virgola
                        final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
                        if (amount != null && amount > 0) {
                          if (isEditing) {
                            // Aggiornamento (non cambiamo lastProcessed per evitare doppioni)
                            await wallet.updateRecurring(existingRecurring!.copyWith(isIncome: isIncome, category: selectedCategory, amount: amount, dayOfMonth: selectedDay, time: selectedTime, payment: selectedPayment, note: noteController.text));
                          } else {
                            // ✅ APPLICA LA LOGICA DATA INTELLIGENTE QUI
                            final initialLastProcessed = _calculateInitialLastProcessed(selectedDay, selectedTime);
                            
                            await wallet.addRecurring(Recurring(
                              isIncome: isIncome,
                              category: selectedCategory,
                              amount: amount,
                              dayOfMonth: selectedDay,
                              time: selectedTime,
                              payment: selectedPayment,
                              note: noteController.text,
                              lastProcessed: initialLastProcessed, // <--- Qui
                            ));
                          }
                          if (context.mounted) Navigator.pop(context);
                        }
                      }))
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER METHODS (DEFINITI INTERNAMENTE ALLA CLASSE) ---

  InputDecoration _noBorderDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label, prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.grey[600]), labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
      border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, errorBorder: InputBorder.none, disabledBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0), isDense: true,
    );
  }

  Widget _buildGlassField({required bool isDark, required Widget child}) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white.withOpacity(0.15) : Colors.white)), child: child);
  }

  Widget _buildGlassButton({required bool isDark, required String label, required Color color, required VoidCallback onTap, bool compact = false, bool isOutlined = false}) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: EdgeInsets.symmetric(vertical: compact ? 10 : 18, horizontal: compact ? 16 : 24), decoration: BoxDecoration(gradient: isOutlined ? null : LinearGradient(colors: [color.withOpacity(0.8), color.withOpacity(0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight), color: isOutlined ? color.withOpacity(0.1) : null, borderRadius: BorderRadius.circular(16), border: Border.all(color: isOutlined ? color : Colors.white.withOpacity(0.3), width: 1.0), boxShadow: isOutlined ? [] : [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]), child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isOutlined ? color : Colors.white, fontSize: compact ? 13 : 16, fontWeight: FontWeight.w600))));
  }

  Widget _buildInfoRow(String label, String value, bool isDark, {Color? color}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600], fontSize: 15)), Text(value, style: TextStyle(color: color ?? (isDark ? Colors.white : Colors.black87), fontSize: 16, fontWeight: FontWeight.bold))]);
  }

  Future<T?> _showGlassDialog<T>({required BuildContext context, required String title, required Widget content, List<Widget>? actions}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<T>(context: context, builder: (ctx) => BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: Dialog(backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.all(20), child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), textAlign: TextAlign.center), const SizedBox(height: 24), content, if (actions != null) ...[const SizedBox(height: 24), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: actions.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: w))).toList())]])))));
  }

  // Funzione pubblica chiamata dal FAB globale della Shell
  void showAddDialog(BuildContext context) {
    final wallet = Provider.of<WalletProvider>(context, listen: false);
    if (_selectedTab == PlanningTab.obiettivi) {
      _showEditGoalSheet(context, wallet, null);
    } else {
      _showEditRecurringSheet(context, wallet, null);
    }
  }
}
