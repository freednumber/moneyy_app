import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../providers.dart';
import 'io_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ SEZIONE TEMA
          _buildCard(
            context,
            'Aspetto',
            Icons.palette,
            [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return SwitchListTile(
                    secondary: const Icon(Icons.dark_mode),
                    title: const Text('Tema scuro'),
                    value: themeProvider.themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      themeProvider.toggleTheme();
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ SEZIONE DATI - Con I/O integrato
          _buildCard(
            context,
            'Gestione Dati',
            Icons.storage,
            [
              ListTile(
                leading: const Icon(Icons.import_export, color: Color(0xFF6366F1)),
                title: const Text('Importa/Esporta'),
                subtitle: const Text('Backup e ripristino dati'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const IOPage()),
                  );
                },
              ),
              const Divider(),
              // ✅ NUOVO: Bottone Reset
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Color(0xFFEF4444)),
                title: const Text('Reset Completo'),
                subtitle: const Text('Elimina tutti i dati dell\'app'),
                trailing: const Icon(Icons.warning, color: Color(0xFFEF4444)),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showResetDialog(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ SEZIONE INFO
          _buildCard(
            context,
            'Informazioni',
            Icons.info,
            [
              const ListTile(
                leading: Icon(Icons.info),
                title: Text('Versione'),
                trailing: Text('1.0.0'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('AI in arrivo'),
                subtitle: const Text('Funzionalità AI presto disponibili'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    'PRESTO',
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ SEZIONE SVILUPPO
          Card(
            color: Colors.grey.shade100,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const ListTile(
              leading: Icon(Icons.code, color: Colors.grey),
              title: Text('Sviluppato da'),
              subtitle: Text('Moneyy Team'),
              trailing: Icon(Icons.favorite, color: Colors.red, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Helper per creare card con sezioni
  Widget _buildCard(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  // ✅ NUOVO: Dialog per reset completo
  void _showResetDialog(BuildContext context) {
    final model = Provider.of<MoneyModel>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Reset Completo'),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.3),
                ),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.delete_forever, color: Color(0xFFEF4444)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⚠️ ATTENZIONE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Questa azione eliminerà PERMANENTEMENTE tutti i dati:',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt, color: Colors.grey, size: 16),
                    SizedBox(width: 8),
                    Text('Tutte le transazioni', style: TextStyle(fontSize: 14)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.flag, color: Colors.grey, size: 16),
                    SizedBox(width: 8),
                    Text('Tutti gli obiettivi', style: TextStyle(fontSize: 14)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.repeat, color: Colors.grey, size: 16),
                    SizedBox(width: 8),
                    Text('Tutte le ricorrenti', style: TextStyle(fontSize: 14)),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '💾 Consigliamo di esportare i dati prima del reset!',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Scrivi "RESET" per confermare:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _ResetConfirmationField(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
        ],
      ),
    );
  }
}

// ✅ Widget per conferma reset
class _ResetConfirmationField extends StatefulWidget {
  @override
  _ResetConfirmationFieldState createState() => _ResetConfirmationFieldState();
}

class _ResetConfirmationFieldState extends State<_ResetConfirmationField> {
  final _controller = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _isValid = _controller.text.trim().toUpperCase() == 'RESET';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<MoneyModel>(context, listen: false);
    
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Scrivi RESET',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isValid ? Colors.red : Colors.grey,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isValid ? Colors.red : Colors.blue,
                width: 2,
              ),
            ),
          ),
          style: TextStyle(
            color: _isValid ? Colors.red : null,
            fontWeight: _isValid ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isValid ? () => _performReset(context, model) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isValid ? Colors.red : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(_isValid ? Icons.delete_forever : Icons.block),
            label: Text(_isValid ? 'RESET DEFINITIVO' : 'Inserisci "RESET"'),
          ),
        ),
      ],
    );
  }

  Future<void> _performReset(BuildContext context, MoneyModel model) async {
    Navigator.pop(context); // Chiudi il dialog
    
    // Mostra progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Reset in corso...'),
            const SizedBox(height: 8),
            Text(
              'Non chiudere l\'app',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );

    try {
      // Elimina tutti i dati
      await model.resetAllData();
      
      Navigator.pop(context); // Chiudi progress dialog
      
      // Mostra successo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Reset completato! L\'app è stata ripulita.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      HapticFeedback.heavyImpact();
    } catch (e) {
      Navigator.pop(context); // Chiudi progress dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Errore durante il reset: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
