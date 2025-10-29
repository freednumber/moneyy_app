import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../providers.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _selectedPeriod = 'This Month';
  String _selectedType = 'All';
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        elevation: 0,
        title: const Text('Transactions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.file_download, color: isDark ? Colors.white : Colors.grey[700]),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchAndFilters(isDark),
            Expanded(
              child: Consumer<MoneyModel>(
                builder: (context, model, child) {
                  final filteredTxs = _getFilteredTransactions(model);
                  return _buildTransactionsList(filteredTxs, model, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: isDark ? Colors.white : Colors.grey[800]),
              decoration: InputDecoration(
                hintText: 'Search transactions',
                hintStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Filter Chips
          Row(
            children: [
              _buildFilterChip(_selectedPeriod, ['This Month', 'Last Month', 'This Year'], (value) => setState(() => _selectedPeriod = value), isDark),
              const SizedBox(width: 12),
              _buildFilterChip(_selectedType, ['All', 'Income', 'Expense'], (value) => setState(() => _selectedType = value), isDark),
              const SizedBox(width: 12),
              _buildFilterChip(_selectedCategory, ['All', 'Spesa', 'Trasporti', 'Svago'], (value) => setState(() => _selectedCategory = value), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String selected, List<String> options, ValueChanged<String> onChanged, bool isDark) {
    return GestureDetector(
      onTap: () => _showFilterOptions(selected, options, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected == 'This Month') const Icon(Icons.calendar_today, size: 16),
            if (selected != 'This Month') const SizedBox(width: 16),
            Text(
              selected,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions(String current, List<String> options, ValueChanged<String> onChanged) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) => ListTile(
          title: Text(option),
          selected: option == current,
          onTap: () {
            onChanged(option);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  Widget _buildTransactionsList(List<MoneyTx> transactions, MoneyModel model, bool isDark) {
    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions found'));
    }

    // Group by date
    final grouped = <String, List<MoneyTx>>{};
    for (final tx in transactions) {
      final dateKey = DateFormat('d MMM, yyyy').format(tx.date);
      grouped[dateKey] ??= [];
      grouped[dateKey]!.add(tx);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final dayTxs = grouped[dateKey]!;
        final dayTotal = dayTxs.fold<double>(0, (sum, tx) => sum + (tx.isIncome ? tx.amount : -tx.amount));
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Text(
                    dateKey,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${dayTotal >= 0 ? '+' : ''}${model.format(dayTotal.abs())}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: dayTotal >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),
            // Transactions
            ...dayTxs.map((tx) => _buildTransactionCard(tx, model, isDark)),
          ],
        );
      },
    );
  }

  Widget _buildTransactionCard(MoneyTx tx, MoneyModel model, bool isDark) {
    final style = model.getTransactionStyle(tx.category);
    final timeFormat = DateFormat('HH:mm a');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
            ),
            child: Icon(style.icon, color: style.color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.category,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  timeFormat.format(tx.date),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${tx.isIncome ? '+' : '-'}${model.format(tx.amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: tx.isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  List<MoneyTx> _getFilteredTransactions(MoneyModel model) {
    var transactions = List<MoneyTx>.from(model.transactions);
    
    // Filter by search
    if (_searchController.text.isNotEmpty) {
      transactions = transactions.where((tx) => 
        tx.category.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }
    
    // Filter by type
    if (_selectedType != 'All') {
      transactions = transactions.where((tx) => 
        _selectedType == 'Income' ? tx.isIncome : !tx.isIncome
      ).toList();
    }
    
    // Filter by category
    if (_selectedCategory != 'All') {
      transactions = transactions.where((tx) => tx.category == _selectedCategory).toList();
    }
    
    return transactions;
  }
}