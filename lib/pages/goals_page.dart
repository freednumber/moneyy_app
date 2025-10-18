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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Obiettivi'),
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
      ),
      body: model.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                await model.loadInitial();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (model.activeGoals.isNotEmpty) ...[
                      const Text(
                        'In Corso',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ...model.activeGoals.map((goal) => _buildGoalCard(goal, model, false)),
                      const SizedBox(height: 24),
                    ],
                    if (model.completedGoals.isNotEmpty) ...[
                      const Text(
                        'Completati',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ...model.completedGoals.map((goal) => _buildGoalCard(goal, model, true)),
                    ],
                    if (model.goals.isEmpty) _buildEmptyState(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showAddGoalDialog(model);
        },
        icon: const Icon(Icons.flag),
        label: const Text('Nuovo Obiettivo'),
        elevation: 6,
      ),
    );
  }

  Widget _buildGoalCard(Goal goal, MoneyModel model, bool isCompleted) {
    final style = model.getGoalStyle(goal.title);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
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
                        colors: [style.color, style.color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: style.color.withOpacity(0.3),
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
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${model.format(goal.saved)} / ${model.format(goal.target)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.grey[600],
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
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.grey, size: 16),
                            SizedBox(width: 4),
                            Text('Saldato', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  if (!goal.isPurchased) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showEditGoalDialog(goal, model),
                      icon: const Icon(Icons.edit),
                      color: style.color,
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
                  minHeight: 8,
                  backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(style.color),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${goal.progress.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: style.color,
                    ),
                  ),
                  if (!goal.isPurchased)
                    Text(
                      'Mancano ${model.format(goal.target - goal.saved)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'Nessun obiettivo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea il tuo primo obiettivo di risparmio',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Nuovo Obiettivo'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: model.goalCategories.map((cat) {
                    final style = model.getGoalStyle(cat);
                    return DropdownMenuItem(
                      value: cat,
                      key: ValueKey('add_goal_$cat'), // ✅ Key unica
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
                  controller: targetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Importo obiettivo (€)',
                    prefixIcon: const Icon(Icons.euro),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annulla')),
              ElevatedButton(
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Obiettivo creato!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Crea'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ✅ FIX: Dropdown con key unica
  void _showEditGoalDialog(Goal goal, MoneyModel model) {
    final targetController = TextEditingController(text: goal.target.toString());
    String selectedCategory = goal.title;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Modifica Obiettivo'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: model.goalCategories.map((cat) {
                    final style = model.getGoalStyle(cat);
                    return DropdownMenuItem(
                      value: cat,
                      key: ValueKey('edit_goal_$cat'), // ✅ FIX: Key unica
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
                  controller: targetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Importo obiettivo (€)',
                    prefixIcon: const Icon(Icons.euro),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Risparmiato: ${model.format(goal.saved)}',
                          style: const TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annulla')),
              ElevatedButton(
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
                        content: Text('Obiettivo aggiornato!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Salva'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showContributeDialog(Goal goal, MoneyModel model) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Contribuisci a ${goal.title}'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Obiettivo: ${model.format(goal.target)}'),
            Text('Salvato: ${model.format(goal.saved)}'),
            Text('Mancano: ${model.format(goal.target - goal.saved)}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Importo da aggiungere',
                prefixIcon: Icon(Icons.euro),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                await model.contributeToGoal(goal.id!, amount);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Aggiunto ${model.format(amount)} a ${goal.title}'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Contribuisci'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(Goal goal, MoneyModel model) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Salda Obiettivo'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'Confermi di voler saldare "${goal.title}"?\n\n'
          'Verrà creata una transazione di uscita di ${model.format(goal.target)}.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () async {
              await model.purchaseGoal(goal.id!);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${goal.title} saldato!'), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
  }

  void _showUnpurchaseDialog(Goal goal, MoneyModel model) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Annulla Saldo'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'Vuoi annullare il saldo di "${goal.title}"?\n\n'
          'La transazione di acquisto verrà eliminata.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Chiudi')),
          ElevatedButton(
            onPressed: () async {
              await model.unpurchaseGoal(goal.id!);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saldo annullato'), backgroundColor: Colors.orange),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Annulla Saldo'),
          ),
        ],
      ),
    );
  }
}
