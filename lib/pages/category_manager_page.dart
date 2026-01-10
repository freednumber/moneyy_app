import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// ✅ IMPORT NUOVO
import '../providers/category_provider.dart';

class CategoryManagerPage extends StatefulWidget {
  const CategoryManagerPage({super.key});

  @override
  State<CategoryManagerPage> createState() => _CategoryManagerPageState();
}

class _CategoryManagerPageState extends State<CategoryManagerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExpenseTab = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _isExpenseTab = _tabController.index == 0;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController();
    IconData selectedIcon = Icons.category;
    Color selectedColor = const Color(0xFF6366F1);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Nuova Categoria',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Nome categoria',
                    hintStyle: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                    ),
                    filled: true,
                    fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Icona:',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    _showIconPicker(context, (icon) {
                      setDialogState(() => selectedIcon = icon);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selectedColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selectedColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(selectedIcon, color: selectedColor, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Cambia',
                          style: TextStyle(
                            color: selectedColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Colore:',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    const Color(0xFF10B981), // Verde
                    const Color(0xFF3B82F6), // Blu
                    const Color(0xFFF59E0B), // Arancione
                    const Color(0xFFEC4899), // Rosa
                    const Color(0xFFEF4444), // Rosso
                    const Color(0xFF6366F1), // Indaco
                    const Color(0xFF8B5CF6), // Viola
                    const Color(0xFF06B6D4), // Ciano
                    const Color(0xFF84CC16), // Lime
                    const Color(0xFFF97316), // Arancione scuro
                    const Color(0xFF14B8A6), // Teal
                    const Color(0xFF6B7280), // Grigio
                  ].map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => selectedColor = color);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 24)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annulla',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  // ✅ USO DEL NUOVO PROVIDER
                  context.read<CategoryProvider>().addCustomCategory(
                        name,
                        selectedIcon,
                        !_isExpenseTab,
                        selectedColor,
                      );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Aggiungi'),
            ),
          ],
        ),
      ),
    );
  }

  void _showIconPicker(BuildContext context, Function(IconData) onSelect) {
    final icons = [
      Icons.shopping_cart,
      Icons.directions_car,
      Icons.restaurant,
      Icons.shopping_bag,
      Icons.receipt_long,
      Icons.smartphone,
      Icons.home,
      Icons.medical_services,
      Icons.fitness_center,
      Icons.card_giftcard,
      Icons.flight,
      Icons.trending_up,
      Icons.work,
      Icons.laptop_mac,
      Icons.category,
      Icons.favorite,
      Icons.sports_soccer,
      Icons.local_cafe,
      Icons.pets,
      Icons.local_gas_station,
      Icons.school,
      Icons.music_note,
      Icons.movie,
      Icons.videogame_asset,
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Scegli Icona',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          width: 300,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  onSelect(icons[index]);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icons[index],
                    size: 32,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showEditCategoryDialog(String category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: category);
    
    // ✅ USO DEL NUOVO PROVIDER
    final provider = context.read<CategoryProvider>();
    final style = provider.getTransactionStyle(category);

    IconData selectedIcon = style.icon;
    Color selectedColor = style.color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Modifica Categoria',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Nome categoria',
                    hintStyle: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                    ),
                    filled: true,
                    fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Icona:',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    _showIconPicker(context, (icon) {
                      setDialogState(() => selectedIcon = icon);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selectedColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selectedColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(selectedIcon, color: selectedColor, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Cambia',
                          style: TextStyle(
                            color: selectedColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Colore:',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    const Color(0xFF10B981),
                    const Color(0xFF3B82F6),
                    const Color(0xFFF59E0B),
                    const Color(0xFFEC4899),
                    const Color(0xFFEF4444),
                    const Color(0xFF6366F1),
                    const Color(0xFF8B5CF6),
                    const Color(0xFF06B6D4),
                    const Color(0xFF84CC16),
                    const Color(0xFFF97316),
                    const Color(0xFF14B8A6),
                    const Color(0xFF6B7280),
                  ].map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => selectedColor = color);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 24)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annulla',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  if (newName != category) {
                    // ✅ USO DEL NUOVO PROVIDER
                    await provider.renameCategory(
                      oldName: category,
                      newName: newName,
                      isIncome: !_isExpenseTab,
                    );
                  }
                  
                  await provider.updateCategoryStyle(
                    categoryName: newName,
                    icon: selectedIcon,
                    color: selectedColor,
                  );
                  if (mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(String category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (category == 'Altro') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Non puoi eliminare la categoria "Altro"'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Elimina Categoria',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Sei sicuro di voler eliminare "$category"?\n\nLe transazioni con questa categoria saranno spostate in "Altro".',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annulla',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // ✅ USO DEL NUOVO PROVIDER
              await context.read<CategoryProvider>().deleteCustomCategory(
                    category,
                    !_isExpenseTab,
                  );
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // ✅ USO DEL NUOVO PROVIDER
    final provider = Provider.of<CategoryProvider>(context);
    
    // Filtriamo "Altro" come facevi prima
    final expenseCategories = provider.allExpenseCats.where((c) => c != 'Altro').toList();
    final incomeCategories = provider.allIncomeCats.where((c) => c != 'Altro').toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          _buildAnimatedTabBar(isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Passiamo il provider
                _buildCategoryList(isDark, expenseCategories, provider, false),
                _buildCategoryList(isDark, incomeCategories, provider, true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Aggiungi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AppBar(
            title: Text(
              'Gestisci Categorie',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
            elevation: 0,
            centerTitle: true,
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.85),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTabBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
              ),
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: _isExpenseTab ? Alignment.centerLeft : Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isExpenseTab
                              ? [Colors.red.withOpacity(0.3), Colors.red.withOpacity(0.15)]
                              : [Colors.green.withOpacity(0.3), Colors.green.withOpacity(0.15)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _tabController.animateTo(0);
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Center(
                            child: Text(
                              'Uscite',
                              style: TextStyle(
                                color: _isExpenseTab
                                    ? Colors.red
                                    : (isDark ? Colors.white70 : Colors.black54),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _tabController.animateTo(1);
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Center(
                            child: Text(
                              'Entrate',
                              style: TextStyle(
                                color: !_isExpenseTab
                                    ? Colors.green
                                    : (isDark ? Colors.white70 : Colors.black54),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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

  // ✅ CORREZIONE: Usa CategoryProvider come tipo per 'provider'
  Widget _buildCategoryList(bool isDark, List<String> categories, CategoryProvider provider, bool isIncome) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: categories.length,
      onReorder: (oldIndex, newIndex) async {
        HapticFeedback.mediumImpact();
        final newOrder = List<String>.from(categories);
        if (newIndex > oldIndex) newIndex--;
        final item = newOrder.removeAt(oldIndex);
        newOrder.insert(newIndex, item);
        await provider.reorderCategories(newOrder, isIncome);
      },
      itemBuilder: (context, index) {
        final category = categories[index];
        final style = provider.getTransactionStyle(category);

        return Padding(
          key: ValueKey(category),
          padding: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      style.color.withOpacity(0.15),
                      style.color.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: style.color.withOpacity(0.3),
                  ),
                ),
                child: ListTile(
                  leading: Icon(
                    style.icon,
                    color: style.color,
                    size: 28,
                  ),
                  title: Text(
                    category,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 20,
                        ),
                        onPressed: () => _showEditCategoryDialog(category),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _showDeleteConfirmDialog(category),
                      ),
                      Icon(
                        Icons.drag_handle,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
