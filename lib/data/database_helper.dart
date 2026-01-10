import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/recurring_model.dart';
import '../models/goal_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('moneyy.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Incrementiamo versione per forzare aggiornamenti futuri se gestiti
      onCreate: _createDB,
      // onUpgrade: _onUpgrade, // Se volessi gestire migrazioni complesse
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const boolType = 'INTEGER';
    const integerType = 'INTEGER';
    const realType = 'REAL';
    const textType = 'TEXT';

    // 1. Tabella Transazioni (Aggiornata con receiptPath, payment, is_recurring)
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        isIncome $boolType,
        category $textType,
        amount $realType,
        date $textType,
        note $textType,
        receiptPath $textType,
        payment $textType,
        is_recurring $boolType
      )
    ''');

    // 2. Tabella Ricorrenti (Aggiornata con lastProcessed)
    await db.execute('''
      CREATE TABLE recurring (
        id $idType,
        isIncome $boolType,
        category $textType,
        amount $realType,
        note $textType,
        dayOfMonth $integerType,
        timeHour $integerType,
        timeMinute $integerType,
        payment $textType,
        lastProcessed $textType
      )
    ''');

    // 3. Tabella Obiettivi
    await db.execute('''
      CREATE TABLE goals (
        id $idType,
        title $textType,
        target $realType,
        saved $realType,
        isPurchased $boolType,
        iconCode $integerType
      )
    ''');
  }
  
  // --- METODI CRUD TRANSAZIONI ---
  
  Future<int> insertTx(MoneyTx tx) async {
    final db = await instance.database;
    return await db.insert('transactions', tx.toMap());
  }

  Future<List<MoneyTx>> getAllTx() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC'); // Ordine cronologico inverso
    return result.map((json) => MoneyTx.fromMap(json)).toList();
  }

  Future<int> updateTx(MoneyTx tx) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<int> deleteTx(int id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // --- METODI CRUD RICORRENTI ---

  Future<int> insertRecurring(Recurring recurring) async {
    final db = await instance.database;
    return await db.insert('recurring', recurring.toMap());
  }

  Future<List<Recurring>> getRecurring() async {
    final db = await instance.database;
    final result = await db.query('recurring');
    return result.map((json) => Recurring.fromMap(json)).toList();
  }

  Future<int> updateRecurring(Recurring recurring) async {
    final db = await instance.database;
    return await db.update(
      'recurring',
      recurring.toMap(),
      where: 'id = ?',
      whereArgs: [recurring.id],
    );
  }

  Future<int> deleteRecurring(int id) async {
    final db = await instance.database;
    return await db.delete(
      'recurring',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- METODI CRUD OBIETTIVI ---

  Future<int> insertGoal(Goal goal) async {
    final db = await instance.database;
    return await db.insert('goals', goal.toMap());
  }

  Future<List<Goal>> getAllGoals() async {
    final db = await instance.database;
    final result = await db.query('goals');
    return result.map((json) => Goal.fromMap(json)).toList();
  }

  Future<int> updateGoal(Goal goal) async {
    final db = await instance.database;
    return await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteGoal(int id) async {
    final db = await instance.database;
    return await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- METODI DI UTILITA' ---
  
  Future<void> deleteTransaction(int id) async => await deleteTx(id); // Alias per compatibilità
  
  Future<List<MoneyTx>> getTransactions() async => await getAllTx(); // Alias

  Future<List<Goal>> getGoals() async => await getAllGoals(); // Alias
  
  Future<void> insertTransaction(MoneyTx tx) async => await insertTx(tx); // Alias

  Future<void> wipeDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'moneyy.db');
    await deleteDatabase(path);
    _database = null;
  }
}
