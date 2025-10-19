import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> with AutomaticKeepAliveClientMixin {
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
          'Obiettivi',
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
      body: model.loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                await model.loadInitial();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (model.activeGoals.isNotEmpty) ...[
                      Text(
                        'In Corso',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...model.activeGoals.map((goal) => _buildGoalCard(goal, model, false, isDark)),
                      const SizedBox(height: 24),
                    ],
                    if (model.completedGoals.isNotEmpty) ...[
                      Text(
                        'Completati',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...model.completedGoals.map((goal) => _buildGoalCard(goal, model, true, isDark)),
                    ],
                    if (model.goals.isEmpty) _buildEmptyState(isDark, model),
                  ],
                ),
              ),
            ),
    );
  }

  // METODO PUBBLICO per essere chiamato dal FAB globale
  void showAddGoalDialog(MoneyModel model) {
    _showAddGoalDialog(model);
  }

  Widget _buildGoalCard(Goal goal, MoneyModel model, bool isCompleted, bool isDark) {
    final style = model.getGoalStyle(goal.title);

    return Dismissible(
      key: Key('goal_${goal.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
          borderRadius: BorderRadius.circular(20),
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
              'Elimina Obiettivo',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            content: Text(
              'Sei sicuro di voler eliminare l\'obiettivo "${goal.title}"?',
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
        model.deleteGoal(goal.id!);
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Obiettivo "${goal.title}" eliminato'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: isDark ? 8 : 2,
        shadowColor: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            if (isCompleted) {
              if (goal.isPurchased) {
                _showUnpurchaseDialog(goal, model);
              } else {
                _showPurchaseDialog(goal, model);
              }
            } else {
              _showContributeDialog(goal, model);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [style.color, style.color.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: style.color.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
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
                            goal.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${model.format(goal.saved)} / ${model.format(goal.target)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[300] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted && !goal.isPurchased)
                      ElevatedButton.icon(
                        onPressed: () => _showPurchaseDialog(goal, model),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Salda'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    if (goal.isPurchased)
                      InkWell(
                        onTap: () => _showUnpurchaseDialog(goal, model),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                              ? Colors.grey.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, color: Colors.grey, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Saldato',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!goal.isPurchased) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _showEditGoalDialog(goal, model),
                        icon: const Icon(Icons.edit),
                        color: isDark ? Colors.grey[300] : style.color,
                        tooltip: 'Modifica obiettivo',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: goal.progress / 100,
                    minHeight: 10,
                    backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(style.color),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: style.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${goal.progress.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : style.color,
                        ),
                      ),
                    ),
                    if (!goal.isPurchased)
                      Text(
                        'Mancano ${model.format(goal.target - goal.saved)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
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

  Widget _buildEmptyState(bool isDark, MoneyModel model) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
              child: const Icon(
                Icons.flag,
                size: 60,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nessun obiettivo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea il tuo primo obiettivo di risparmio',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog(MoneyModel model) {
    final targetController = TextEditingController();
    String selectedCategory = model.goalCategories.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    HapticFeedback.mediumImpact(); // Feedback al tap

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          if (!model.goalCategories.contains(selectedCategory)) {
            selectedCategory = model.goalCategories.first;
          }
          
          return AlertDialog(
            backgroundColor: isDark ? Colors.grey[900] : Colors.white,
            title: Row(
              children: [
                const Icon(Icons.flag, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Text(
                  'Nuovo Obiettivo',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: Icon(
                      model.getGoalStyle(selectedCategory).icon,
                      color: model.getGoalStyle(selectedCategory).color,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : null,
                    ),
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
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Importo obiettivo (€)',
                    prefixIcon: const Icon(Icons.euro),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    hintText: '500.00',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : null,
                    ),
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ),
                ),
              ],
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
                    HapticFeedback.heavyImpact(); // Feedback al salvataggio
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Obiettivo creato!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Inserisci un importo valido'),
                        backgroundColor: Colors.red,
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
            ],
          );
        },
      ),
    );
  }

  void _showEditGoalDialog(Goal goal, MoneyModel model) {
    final targetController = TextEditingController(text: goal.target.toString());
    String selectedCategory = goal.title;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (!model.goalCategories.contains(selectedCategory)) {
      selectedCategory = model.goalCategories.first;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: isDark ? Colors.grey[900] : Colors.white,
            title: Row(
              children: [
                const Icon(Icons.edit, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Text(
                  'Modifica Obiettivo',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: Icon(
                      model.getGoalStyle(selectedCategory).icon,
                      color: model.getGoalStyle(selectedCategory).color,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : null,
                    ),
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
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Importo obiettivo (€)',
                    prefixIcon: const Icon(Icons.euro),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                      ? Colors.blue.withOpacity(0.15)
                      : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Risparmiato: ${model.format(goal.saved)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF60A5FA) : Colors.blue,
                            fontWeight: FontWeight.w500,
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
                  final target = double.tryParse(targetController.text);
                  if (target != null && target > 0) {
                    final updated = Goal(
                      id: goal.id,
                      title: selectedCategory,
                      target: target,
                      saved: goal.saved,
                      isPurchased: goal.isPurchased,
                    );
                    await model.updateGoal(updated);
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Obiettivo aggiornato!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Salva'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showContributeDialog(Goal goal, MoneyModel model) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          'Contribuisci a ${goal.title}',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Obiettivo: ${model.format(goal.target)}',
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.black87,
              ),
            ),
            Text(
              'Salvato: ${model.format(goal.saved)}',
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.black87,
              ),
            ),
            Text(
              'Mancano: ${model.format(goal.target - goal.saved)}',
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'Importo da aggiungere',
                prefixIcon: const Icon(Icons.euro),
                labelStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : null,
                ),
              ),
              autofocus: true,
            ),
          ],
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
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                await model.contributeToGoal(goal.id!, amount);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Aggiunto ${model.format(amount)} a ${goal.title}'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Contribuisci'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(Goal goal, MoneyModel model) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          'Salda Obiettivo',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'Confermi di voler saldare "${goal.title}"?\n\n'
          'Verrà creata una transazione di uscita di ${model.format(goal.target)}.',
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.black87,
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
          ElevatedButton(
            onPressed: () async {
              await model.purchaseGoal(goal.id!);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${goal.title} saldato!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Conferma', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUnpurchaseDialog(Goal goal, MoneyModel model) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          'Annulla Saldo',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'Vuoi annullare il saldo di "${goal.title}"?\n\n'
          'La transazione di acquisto verrà eliminata.',
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Chiudi',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await model.unpurchaseGoal(goal.id!);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saldo annullato'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Annulla Saldo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}