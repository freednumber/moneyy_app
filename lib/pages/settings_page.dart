import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
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
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('Tema scuro'),
                  trailing: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return Switch(
                        value: themeProvider.themeMode == ThemeMode.dark,
                        onChanged: (value) {
                          themeProvider.toggleTheme();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ✅ SEZIONE DATI - Con I/O integrato
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.import_export, color: Color(0xFF6366F1)),
                  title: const Text('Importa/Esporta'),
                  subtitle: const Text('Backup e ripristino dati'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const IOPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ✅ SEZIONE INFO
          Card(
            child: Column(
              children: [
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
          ),
          const SizedBox(height: 16),

          // ✅ SEZIONE SVILUPPO
          Card(
            color: Colors.grey.shade100,
            child: ListTile(
              leading: const Icon(Icons.code, color: Colors.grey),
              title: const Text('Sviluppato da'),
              subtitle: const Text('Moneyy Team'),
              trailing: const Icon(Icons.favorite, color: Colors.red, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
