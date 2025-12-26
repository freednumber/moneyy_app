import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class MoneyRepository {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'moneyy.db');
    _database = await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        isIncome INTEGER NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        payment TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        target REAL NOT NULL,
        saved REAL NOT NULL,
        isPurchased INTEGER NOT NULL DEFAULT 0,
        category TEXT,
        iconCodePoint INTEGER,
        iconFontFamily TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        isIncome INTEGER NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        dayOfMonth INTEGER NOT NULL,
        timeHour INTEGER NOT NULL,
        timeMinute INTEGER NOT NULL,
        payment TEXT NOT NULL,
        note TEXT,
        lastProcessed TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE goals ADD COLUMN iconCodePoint INTEGER');
        await db.execute('ALTER TABLE goals ADD COLUMN iconFontFamily TEXT');
      } catch (e) {
        // Columns might already exist
      }
    }
    
    if (oldVersion < 3) {
    try {
      await db.execute('ALTER TABLE goals ADD COLUMN category TEXT');
    } catch (e) {
      // Column might already exist
    }
  }

  // 🔥 AGGIUNGI QUESTA NUOVA MIGRAZIONE
  if (oldVersion < 4) {
    try {
      await db.execute('ALTER TABLE goals ADD COLUMN iconCodePoint INTEGER');
      await db.execute('ALTER TABLE goals ADD COLUMN iconFontFamily TEXT');
    } catch (e) {
      // Columns might already exist - that's OK
      print('Icon columns already exist or error: $e');
    }
  }
}

  // ✅ TRANSACTIONS
  Future<List<MoneyTx>> getAllTx() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => MoneyTx.fromMap(maps[i]));
  }

  Future<void> insertTx(MoneyTx tx) async {
    final db = await database;
    await db.insert('transactions', tx.toMap());
  }

  Future<void> updateTx(MoneyTx tx) async {
    final db = await database;
    await db.update('transactions', tx.toMap(), where: 'id = ?', whereArgs: [tx.id]);
  }

  Future<void> deleteTx(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> renameCategoryInTransactions(String oldName, String newName) async {
    final db = await database;
    await db.update('transactions', {'category': newName}, where: 'category = ?', whereArgs: [oldName]);
  }

  // ✅ GOALS
  Future<List<Goal>> getAllGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('goals');
    return List.generate(maps.length, (i) => Goal.fromMap(maps[i]));
  }

  Future<void> insertGoal(Goal goal) async {
    final db = await database;
    await db.insert('goals', goal.toMap());
  }

  Future<void> updateGoal(Goal goal) async {
    final db = await database;
    await db.update('goals', goal.toMap(), where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<void> deleteGoal(int id) async {
    final db = await database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  // ✅ RECURRING
  Future<List<Recurring>> getRecurring() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('recurring');
    return List.generate(maps.length, (i) => Recurring.fromMap(maps[i]));
  }

  Future<void> insertRecurring(Recurring recurring) async {
    final db = await database;
    await db.insert('recurring', recurring.toMap());
  }

  Future<void> updateRecurring(Recurring recurring) async {
    final db = await database;
    await db.update('recurring', recurring.toMap(), where: 'id = ?', whereArgs: [recurring.id]);
  }

  Future<void> deleteRecurring(int id) async {
    final db = await database;
    await db.delete('recurring', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> renameCategoryInRecurrings(String oldName, String newName) async {
    final db = await database;
    await db.update('recurring', {'category': newName}, where: 'category = ?', whereArgs: [oldName]);
  }

  // ✅ RESET
  Future<void> resetDatabase() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('goals');
    await db.delete('recurring');
  }
}
