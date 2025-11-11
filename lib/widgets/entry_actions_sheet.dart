import 'package:flutter/material.dart';
import '../widgets/liquid_glass_card.dart';

class EntryActionsSheet extends StatelessWidget {
  final VoidCallback onIncome;
  final VoidCallback onExpense;
  final VoidCallback onScanReceipt;

  const EntryActionsSheet({
    super.key,
    required this.onIncome,
    required this.onExpense,
    required this.onScanReceipt,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LiquidGlassButton(
            onPressed: onIncome,
            borderRadius: 22,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_downward, color: Colors.greenAccent),
                SizedBox(width: 10),
                Text('Entrata', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SizedBox(height: 16),
          LiquidGlassButton(
            onPressed: onExpense,
            borderRadius: 22,
            glassColor: const Color(0x44EF4444),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_upward, color: Colors.redAccent),
                SizedBox(width: 10),
                Text('Uscita', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SizedBox(height: 16),
          LiquidGlassButton(
            onPressed: onScanReceipt,
            borderRadius: 22,
            glassColor: const Color(0x4478B3FD),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long, color: Colors.blueAccent),
                SizedBox(width: 10),
                Text('Scansiona Scontrino', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SizedBox(height: 18),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Annulla', style: TextStyle(color: Colors.white70, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }
}
