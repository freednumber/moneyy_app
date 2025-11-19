import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;  // CAMBIATO: da SavingsGoal a Goal
  final VoidCallback onAddMoney;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final bool isDark;

  const GoalCard({
    Key? key,
    required this.goal,
    required this.onAddMoney,
    required this.onComplete,
    required this.onEdit,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.savings, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        goal.title,  // CAMBIATO: da goal.name a goal.title
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: isDark ? Colors.white70 : Colors.grey[600]),
                onPressed: onEdit,
                tooltip: 'Modifica obiettivo',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goal.progress / 100,  // CAMBIATO: usa goal.progress
              minHeight: 10,
              backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                goal.isCompleted ? const Color(0xFF10B981) : const Color(0xFF6366F1),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${goal.saved.toStringAsFixed(2)}€ / ${goal.target.toStringAsFixed(2)}€',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goal.isCompleted ? 'Obiettivo raggiunto! 🎉' : 'Mancano ${(goal.target - goal.saved).toStringAsFixed(2)}€',
                    style: TextStyle(
                      fontSize: 12,
                      color: goal.isCompleted ? const Color(0xFF10B981) : (isDark ? Colors.white60 : Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: goal.isCompleted ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFF6366F1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${goal.progress.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: goal.isCompleted ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Aggiungi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onAddMoney,
                ),
              ),
              if (goal.isCompleted && !goal.isPurchased) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Completa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onComplete,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
