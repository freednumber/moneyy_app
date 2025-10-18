import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class Repository {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'moneyy.db');
    return await openDatabase(
      path,
      version: 2,  // ✅ Versione aggiornata
      onCreate: _createDb,
      onUpgrade: _onUpgrade,  // ✅ Gestisce l'aggiornamento
    );
  }

  // ✅ Metodo per aggiornare il database
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Ricrea le tabelle con la struttura corretta
      await db.execute('DROP TABLE IF EXISTS transactions');
      await db.execute('DROP TABLE IF EXISTS goals');
      await db.execute('DROP TABLE IF EXISTS recurring');
      await _createDb(db, newVersion);
    }
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        isIncome INTEGER NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        payment INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        target REAL NOT NULL,
        saved REAL NOT NULL,
        isPurchased INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        dayOfMonth INTEGER NOT NULL,
        payment INTEGER NOT NULL,
        note TEXT,
        lastProcessed TEXT
      )
    ''');
  }

  // TRANSACTIONS
  Future<void> insertTx(MoneyTx tx) async {
    final db = await database;
    await db.insert('transactions', tx.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTx(MoneyTx tx) async {
    final db = await database;
    await db.update('transactions', tx.toMap(), where: 'id = ?', whereArgs: [tx.id]);
  }

  Future<void> deleteTx(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MoneyTx>> getAllTx() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((m) => MoneyTx.fromMap(m)).toList();
  }

  // GOALS
  Future<void> insertGoal(Goal g) async {
    final db = await database;
    await db.insert('goals', g.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateGoal(Goal g) async {
    final db = await database;
    await db.update('goals', g.toMap(), where: 'id = ?', whereArgs: [g.id]);
  }

  Future<void> deleteGoal(int id) async {
    final db = await database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Goal>> getAllGoals() async {
    final db = await database;
    final maps = await db.query('goals');
    return maps.map((m) => Goal.fromMap(m)).toList();
  }

  // RECURRING
  Future<void> insertRecurring(Recurring r) async {
    final db = await database;
    await db.insert('recurring', r.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateRecurring(Recurring r) async {
    final db = await database;
    await db.update('recurring', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
  }

  Future<void> deleteRecurring(int id) async {
    final db = await database;
    await db.delete('recurring', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Recurring>> getRecurring() async {
    final db = await database;
    final maps = await db.query('recurring', orderBy: 'dayOfMonth ASC');
    return maps.map((m) => Recurring.fromMap(m)).toList();
  }
}
