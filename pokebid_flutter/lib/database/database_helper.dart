import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pokebid.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // Cached sets table
    await db.execute('''
      CREATE TABLE cached_sets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        series TEXT,
        release_date TEXT,
        symbol_image TEXT,
        logo_image TEXT,
        total INTEGER DEFAULT 0,
        cached_at INTEGER NOT NULL
      )
    ''');

    // Cached cards table
    await db.execute('''
      CREATE TABLE cached_cards (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        image_small TEXT,
        image_large TEXT,
        rarity TEXT,
        set_name TEXT,
        set_id TEXT,
        number TEXT,
        supertype TEXT,
        types TEXT,
        estimated_price_ntd INTEGER DEFAULT 0,
        tcgplayer_json TEXT,
        cached_at INTEGER NOT NULL
      )
    ''');

    // User collection table
    await db.execute('''
      CREATE TABLE collection (
        card_id TEXT PRIMARY KEY,
        card_name TEXT NOT NULL,
        set_name TEXT,
        image_small TEXT,
        rarity TEXT,
        estimated_price_ntd INTEGER DEFAULT 0,
        added_at INTEGER NOT NULL,
        notes TEXT
      )
    ''');

    // Recent transactions (mock / user-entered)
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_id TEXT NOT NULL,
        card_name TEXT NOT NULL,
        grade TEXT,
        price_ntd INTEGER NOT NULL,
        buyer TEXT,
        date TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  // ── Sets ──────────────────────────────────────────────────────────────────

  Future<void> cacheSets(List<Map<String, dynamic>> sets) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();
    for (final s in sets) {
      batch.insert('cached_sets', {...s, 'cached_at': now},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedSets() async {
    final db = await database;
    return db.query('cached_sets', orderBy: 'release_date DESC');
  }

  Future<bool> isSetsStale() async {
    final db = await database;
    final rows = await db.query('cached_sets',
        columns: ['cached_at'], orderBy: 'cached_at DESC', limit: 1);
    if (rows.isEmpty) return true;
    final cachedAt = rows.first['cached_at'] as int;
    final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
    // Stale after 24 hours
    return age > 1000 * 60 * 60 * 24;
  }

  // ── Cards ─────────────────────────────────────────────────────────────────

  Future<void> cacheCards(List<Map<String, dynamic>> cards) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();
    for (final c in cards) {
      batch.insert('cached_cards', {...c, 'cached_at': now},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedCardsForSet(String setId) async {
    final db = await database;
    return db.query('cached_cards',
        where: 'set_id = ?', whereArgs: [setId], orderBy: 'CAST(number AS INTEGER)');
  }

  Future<bool> isSetCardsCached(String setId) async {
    final db = await database;
    final rows = await db.query('cached_cards',
        columns: ['cached_at'],
        where: 'set_id = ?',
        whereArgs: [setId],
        orderBy: 'cached_at DESC',
        limit: 1);
    if (rows.isEmpty) return false;
    final cachedAt = rows.first['cached_at'] as int;
    final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
    // Stale after 6 hours
    return age < 1000 * 60 * 60 * 6;
  }

  // ── Collection ────────────────────────────────────────────────────────────

  Future<void> addToCollection(Map<String, dynamic> card) async {
    final db = await database;
    await db.insert(
      'collection',
      {...card, 'added_at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFromCollection(String cardId) async {
    final db = await database;
    await db.delete('collection', where: 'card_id = ?', whereArgs: [cardId]);
  }

  Future<List<Map<String, dynamic>>> getCollection() async {
    final db = await database;
    return db.query('collection', orderBy: 'added_at DESC');
  }

  Future<bool> isInCollection(String cardId) async {
    final db = await database;
    final rows = await db.query('collection',
        where: 'card_id = ?', whereArgs: [cardId], limit: 1);
    return rows.isNotEmpty;
  }

  Future<int> getCollectionTotalValue() async {
    final db = await database;
    final result = await db
        .rawQuery('SELECT SUM(estimated_price_ntd) as total FROM collection');
    return (result.first['total'] as int?) ?? 0;
  }

  Future<Set<String>> getCollectedCardIds() async {
    final db = await database;
    final rows = await db.query('collection', columns: ['card_id']);
    return rows.map((r) => r['card_id'] as String).toSet();
  }

  // ── Transactions ──────────────────────────────────────────────────────────

  Future<void> insertTransaction(Map<String, dynamic> tx) async {
    final db = await database;
    await db.insert('transactions',
        {...tx, 'created_at': DateTime.now().millisecondsSinceEpoch});
  }

  Future<List<Map<String, dynamic>>> getTransactionsForCard(String cardId) async {
    final db = await database;
    return db.query('transactions',
        where: 'card_id = ?',
        whereArgs: [cardId],
        orderBy: 'date DESC',
        limit: 20);
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    return db.query('transactions', orderBy: 'date DESC');
  }
}
