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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark 
        ? const Color(0xFF0F172A)
        : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Impostazioni',
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
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // SEZIONE TEMA
                _buildCard(
                  context,
                  'Aspetto',
                  Icons.palette,
                  isDark,
                  [
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return SwitchListTile(
                          secondary: Icon(
                            Icons.dark_mode,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                          title: Text(
                            'Tema scuro',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'Attiva il tema scuro per l\'app',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          value: themeProvider.themeMode == ThemeMode.dark,
                          activeColor: const Color(0xFF6366F1),
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

                // SEZIONE DATI
                _buildCard(
                  context,
                  'Gestione Dati',
                  Icons.storage,
                  isDark,
                  [
                    ListTile(
                      leading: Icon(
                        Icons.import_export,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF6366F1), // Verde lime in dark
                      ),
                      title: Text(
                        'Importa/Esporta',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Backup e ripristino dati',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const IOPage()),
                        );
                      },
                    ),
                    Divider(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300],
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Color(0xFFEF4444)),
                      title: Text(
                        'Reset Completo',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Elimina tutti i dati dell\'app',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      trailing: const Icon(Icons.warning, color: Color(0xFFEF4444)),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _showResetDialog(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // SEZIONE INFO
                _buildCard(
                  context,
                  'Informazioni',
                  Icons.info,
                  isDark,
                  [
                    ListTile(
                      leading: Icon(
                        Icons.info,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                      title: Text(
                        'Versione',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Text(
                        '1.0.0',
                        style: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Divider(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300],
                    ),
                    ListTile(
                      leading: const Icon(Icons.star, color: Color(0xFF6366F1)),
                      title: Text(
                        'AI in arrivo',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Funzionalità AI presto disponibili',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                            ? const Color(0xFF6366F1).withOpacity(0.2)
                            : const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF6366F1).withOpacity(isDark ? 0.4 : 0.3),
                          ),
                        ),
                        child: Text(
                          'PRESTO',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8B9BFF) : const Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // FOOTER SVILUPPATO DA - PIÙ VISIBILE IN DARK
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                  ? [
                      Colors.grey[800]!.withOpacity(0.95), // Sfondo più chiaro in dark
                      Colors.grey[700]!.withOpacity(0.85),
                    ]
                  : [
                      Colors.grey[100]!,
                      Colors.grey[50]!,
                    ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                  ? Colors.white.withOpacity(0.25) // Bordo più forte
                  : Colors.grey.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                            ? [const Color(0xFF34D399), const Color(0xFF10B981)] // Verde lime in dark
                            : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? const Color(0xFF34D399) : const Color(0xFF6366F1)).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.code,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sviluppato da',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[200] : Colors.grey[600], // Più chiaro in dark
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // APP NAME E TEAM
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                            ? [const Color(0xFF34D399), const Color(0xFF10B981)] // Verde lime per logo
                            : [const Color(0xFF10B981), const Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.euro,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'MoneyY',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87, // Bianco puro in dark
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '•',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[200] : Colors.grey[500], // Più chiaro in dark
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Tema',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[200] : Colors.grey[600], // Più chiaro in dark
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // FREEDNUMBER CON STILE PIÙ VISIBILE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                        ? [const Color(0xFF6366F1).withOpacity(0.3), const Color(0xFF8B5CF6).withOpacity(0.3)] // Più opaco in dark
                        : [const Color(0xFF6366F1).withOpacity(0.1), const Color(0xFF8B5CF6).withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(isDark ? 0.6 : 0.3), // Bordo più forte in dark
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person,
                        size: 18,
                        color: isDark ? Colors.white : const Color(0xFF6366F1), // Bianco in dark
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'freednumber',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF6366F1), // Bianco in dark
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // CUORE E VERSIONE
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Fatto con',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[200] : Colors.grey[500], // Più chiaro in dark
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'per la gestione finanziaria',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[200] : Colors.grey[500], // Più chiaro in dark
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, bool isDark, List<Widget> children) {
    return Card(
      color: isDark 
        ? Colors.grey[900]!.withOpacity(0.8)
        : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: isDark ? 8 : 2,
      shadowColor: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    final model = Provider.of<MoneyModel>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.warning, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text(
              'Reset Completo',
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.4),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.delete_forever, color: Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⚠️ ATTENZIONE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Questa azione eliminerà PERMANENTEMENTE tutti i dati:',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[300] : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Tutte le transazioni',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[300] : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.flag, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Tutti gli obiettivi',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[300] : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.repeat, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Tutte le ricorrenti',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[300] : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '💾 Consigliamo di esportare i dati prima del reset!',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark ? const Color(0xFFFFB347) : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Scrivi "RESET" per confermare:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _ResetConfirmationField(isDark: isDark),
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
        ],
      ),
    );
  }
}

class _ResetConfirmationField extends StatefulWidget {
  final bool isDark;
  const _ResetConfirmationField({required this.isDark});

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
          style: TextStyle(
            color: _isValid 
              ? Colors.red
              : widget.isDark ? Colors.white : Colors.black87,
            fontWeight: _isValid ? FontWeight.bold : FontWeight.normal,
          ),
          decoration: InputDecoration(
            hintText: 'Scrivi RESET',
            hintStyle: TextStyle(
              color: widget.isDark ? Colors.grey[500] : Colors.grey[400],
            ),
            filled: true,
            fillColor: widget.isDark 
              ? Colors.grey[800]!.withOpacity(0.6)
              : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isValid 
                  ? Colors.red
                  : widget.isDark ? Colors.grey[600]! : Colors.grey[300]!,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isValid ? Colors.red : const Color(0xFF6366F1),
                width: 2,
              ),
            ),
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
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: _isValid ? 4 : 0,
            ),
            icon: Icon(_isValid ? Icons.delete_forever : Icons.block),
            label: Text(
              _isValid ? 'RESET DEFINITIVO' : 'Inserisci "RESET"',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _performReset(BuildContext context, MoneyModel model) async {
    Navigator.pop(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF6366F1)),
            const SizedBox(height: 16),
            Text(
              'Reset in corso...',
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Non chiudere l\'app',
              style: TextStyle(
                fontSize: 12,
                color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );

    try {
      await model.resetAllData();
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Reset completato! L\'app è stata ripulita.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      HapticFeedback.heavyImpact();
    } catch (e) {
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Errore durante il reset: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}