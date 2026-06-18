import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction_item.dart';
import '../models/monthly_summary.dart';
import '../models/income_source.dart';
import '../models/payment_method.dart';
import '../models/expense_category.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  // Web in-memory storage
  static List<Map<String, dynamic>>? _webDb;
  static List<Map<String, dynamic>>? _webIncomeSources;
  static List<Map<String, dynamic>>? _webPaymentMethods;
  static List<Map<String, dynamic>>? _webExpenseCategories;

  DbHelper._init();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite no está soportado en la plataforma Web.');
    }
    if (_database != null) return _database!;
    _database = await _initDB('mis_finanzas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // --- Schema creation (fresh install) ---

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE income_sources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE payment_methods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        display_name TEXT NOT NULL,
        section TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        parent_id INTEGER,
        income_source_id INTEGER,
        payment_method_id INTEGER,
        FOREIGN KEY (parent_id) REFERENCES transactions(id) ON DELETE CASCADE,
        FOREIGN KEY (income_source_id) REFERENCES income_sources(id),
        FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id)
      )
    ''');

    await _seedExpenseCategories(db);
    await _seedDefaults(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN parent_id INTEGER');
      await db.execute('ALTER TABLE transactions ADD COLUMN income_source_id INTEGER');
      await db.execute('ALTER TABLE transactions ADD COLUMN payment_method_id INTEGER');

      await db.execute('''
        CREATE TABLE income_sources (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');
      await db.execute('''
        CREATE TABLE payment_methods (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');
      await db.execute('''
        CREATE TABLE expense_categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT NOT NULL UNIQUE,
          display_name TEXT NOT NULL,
          section TEXT NOT NULL
        )
      ''');

      await _seedExpenseCategories(db);

      // Migrate existing income categories to income_sources
      const migrationMap = {
        'sueldo': 'Sueldo',
        'ventas': 'Ventas',
        'pagos_tercero': 'Pagos de Terceros',
      };
      for (final entry in migrationMap.entries) {
        await db.insert('income_sources', {'name': entry.value},
            conflictAlgorithm: ConflictAlgorithm.ignore);
        final sources = await db.query('income_sources',
            where: 'name = ?', whereArgs: [entry.value]);
        if (sources.isNotEmpty) {
          await db.update(
            'transactions',
            {'income_source_id': sources.first['id']},
            where: "type = 'income' AND category = ?",
            whereArgs: [entry.key],
          );
        }
      }

      // Migrate cost categories
      const costMigration = {
        'tarjetas': 'tarjeta_credito',
        'prestamos': 'prestamo',
        'pagos_basicos': 'arriendo_dividendo',
        'compras': 'compras',
        'otros': 'otros',
      };
      for (final entry in costMigration.entries) {
        await db.update(
          'transactions',
          {'category': entry.value},
          where: "type = 'cost' AND category = ?",
          whereArgs: [entry.key],
        );
      }

      await db.insert('payment_methods', {'name': 'Efectivo'},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _seedExpenseCategories(Database db) async {
    const categories = [
      {'key': 'arriendo_dividendo', 'display_name': 'Arriendo / Dividendo', 'section': 'indispensable'},
      {'key': 'luz', 'display_name': 'Luz', 'section': 'indispensable'},
      {'key': 'agua', 'display_name': 'Agua', 'section': 'indispensable'},
      {'key': 'gas', 'display_name': 'Gas', 'section': 'indispensable'},
      {'key': 'internet', 'display_name': 'Internet', 'section': 'indispensable'},
      {'key': 'tarjeta_credito', 'display_name': 'Tarjeta de Crédito', 'section': 'recurrente'},
      {'key': 'prestamo', 'display_name': 'Préstamo', 'section': 'recurrente'},
      {'key': 'seguro', 'display_name': 'Seguro', 'section': 'recurrente'},
      {'key': 'suscripcion', 'display_name': 'Suscripción', 'section': 'recurrente'},
      {'key': 'compras', 'display_name': 'Compras', 'section': 'extraordinario'},
      {'key': 'salidas', 'display_name': 'Salidas', 'section': 'extraordinario'},
      {'key': 'regalos', 'display_name': 'Regalos', 'section': 'extraordinario'},
      {'key': 'medico', 'display_name': 'Médico', 'section': 'extraordinario'},
      {'key': 'otros', 'display_name': 'Otros', 'section': 'extraordinario'},
    ];
    for (final cat in categories) {
      await db.insert('expense_categories', cat,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _seedDefaults(Database db) async {
    await db.insert('income_sources', {'name': 'Sueldo'},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('income_sources', {'name': 'Ventas'},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('payment_methods', {'name': 'Efectivo'},
        conflictAlgorithm: ConflictAlgorithm.ignore);

    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);

    String isoDate(DateTime date, int day) {
      return DateTime(date.year, date.month, day, 12, 0).toIso8601String();
    }

    final sueldoSources = await db.query('income_sources',
        where: 'name = ?', whereArgs: ['Sueldo']);
    final sueldoId = sueldoSources.first['id'] as int;
    final ventasSources = await db.query('income_sources',
        where: 'name = ?', whereArgs: ['Ventas']);
    final ventasId = ventasSources.first['id'] as int;

    final initialData = [
      {'type': 'income', 'category': 'sueldo', 'amount': 2500.0, 'description': 'Sueldo mensual', 'date': isoDate(lastMonth, 5), 'income_source_id': sueldoId},
      {'type': 'income', 'category': 'ventas', 'amount': 450.0, 'description': 'Venta de artículos usados', 'date': isoDate(lastMonth, 15), 'income_source_id': ventasId},
      {'type': 'income', 'category': 'pagos_tercero', 'amount': 150.0, 'description': 'Reembolso de cena', 'date': isoDate(lastMonth, 20)},
      {'type': 'cost', 'category': 'tarjeta_credito', 'amount': 600.0, 'description': 'Tarjeta de Crédito Visa', 'date': isoDate(lastMonth, 10)},
      {'type': 'cost', 'category': 'prestamo', 'amount': 300.0, 'description': 'Cuota crédito de consumo', 'date': isoDate(lastMonth, 12)},
      {'type': 'cost', 'category': 'arriendo_dividendo', 'amount': 250.0, 'description': 'Luz, agua e internet', 'date': isoDate(lastMonth, 5)},
      {'type': 'cost', 'category': 'compras', 'amount': 400.0, 'description': 'Supermercado mensual', 'date': isoDate(lastMonth, 8)},
      {'type': 'income', 'category': 'sueldo', 'amount': 2500.0, 'description': 'Sueldo mensual', 'date': isoDate(now, 5), 'income_source_id': sueldoId},
      {'type': 'cost', 'category': 'arriendo_dividendo', 'amount': 260.0, 'description': 'Luz, agua y gas', 'date': isoDate(now, 5)},
      {'type': 'cost', 'category': 'compras', 'amount': 180.0, 'description': 'Compra supermercado semana 1', 'date': isoDate(now, 7)},
    ];

    for (var data in initialData) {
      await db.insert('transactions', data);
    }
  }

  // --- Web fallback initialization ---

  void _initWebDb() {
    if (_webDb != null) return;

    _webExpenseCategories = [
      {'id': 1, 'key': 'arriendo_dividendo', 'display_name': 'Arriendo / Dividendo', 'section': 'indispensable'},
      {'id': 2, 'key': 'luz', 'display_name': 'Luz', 'section': 'indispensable'},
      {'id': 3, 'key': 'agua', 'display_name': 'Agua', 'section': 'indispensable'},
      {'id': 4, 'key': 'gas', 'display_name': 'Gas', 'section': 'indispensable'},
      {'id': 5, 'key': 'internet', 'display_name': 'Internet', 'section': 'indispensable'},
      {'id': 6, 'key': 'tarjeta_credito', 'display_name': 'Tarjeta de Crédito', 'section': 'recurrente'},
      {'id': 7, 'key': 'prestamo', 'display_name': 'Préstamo', 'section': 'recurrente'},
      {'id': 8, 'key': 'seguro', 'display_name': 'Seguro', 'section': 'recurrente'},
      {'id': 9, 'key': 'suscripcion', 'display_name': 'Suscripción', 'section': 'recurrente'},
      {'id': 10, 'key': 'compras', 'display_name': 'Compras', 'section': 'extraordinario'},
      {'id': 11, 'key': 'salidas', 'display_name': 'Salidas', 'section': 'extraordinario'},
      {'id': 12, 'key': 'regalos', 'display_name': 'Regalos', 'section': 'extraordinario'},
      {'id': 13, 'key': 'medico', 'display_name': 'Médico', 'section': 'extraordinario'},
      {'id': 14, 'key': 'otros', 'display_name': 'Otros', 'section': 'extraordinario'},
    ];

    _webIncomeSources = [
      {'id': 1, 'name': 'Sueldo'},
      {'id': 2, 'name': 'Ventas'},
    ];

    _webPaymentMethods = [
      {'id': 1, 'name': 'Efectivo'},
    ];

    _webDb = [];
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);

    String isoDate(DateTime date, int day) {
      return DateTime(date.year, date.month, day, 12, 0).toIso8601String();
    }

    final initialData = [
      {'type': 'income', 'category': 'sueldo', 'amount': 2500.0, 'description': 'Sueldo mensual', 'date': isoDate(lastMonth, 5), 'income_source_id': 1},
      {'type': 'income', 'category': 'ventas', 'amount': 450.0, 'description': 'Venta de artículos usados', 'date': isoDate(lastMonth, 15), 'income_source_id': 2},
      {'type': 'income', 'category': 'pagos_tercero', 'amount': 150.0, 'description': 'Reembolso de cena', 'date': isoDate(lastMonth, 20)},
      {'type': 'cost', 'category': 'tarjeta_credito', 'amount': 600.0, 'description': 'Tarjeta de Crédito Visa', 'date': isoDate(lastMonth, 10)},
      {'type': 'cost', 'category': 'prestamo', 'amount': 300.0, 'description': 'Cuota crédito de consumo', 'date': isoDate(lastMonth, 12)},
      {'type': 'cost', 'category': 'arriendo_dividendo', 'amount': 250.0, 'description': 'Luz, agua e internet', 'date': isoDate(lastMonth, 5)},
      {'type': 'cost', 'category': 'compras', 'amount': 400.0, 'description': 'Supermercado mensual', 'date': isoDate(lastMonth, 8)},
      {'type': 'income', 'category': 'sueldo', 'amount': 2500.0, 'description': 'Sueldo mensual', 'date': isoDate(now, 5), 'income_source_id': 1},
      {'type': 'cost', 'category': 'arriendo_dividendo', 'amount': 260.0, 'description': 'Luz, agua y gas', 'date': isoDate(now, 5)},
      {'type': 'cost', 'category': 'compras', 'amount': 180.0, 'description': 'Compra supermercado semana 1', 'date': isoDate(now, 7)},
    ];

    int idCounter = 1;
    for (var data in initialData) {
      final map = Map<String, dynamic>.from(data);
      map['id'] = idCounter++;
      map['parent_id'] = null;
      map.putIfAbsent('income_source_id', () => null);
      map.putIfAbsent('payment_method_id', () => null);
      _webDb!.add(map);
    }
  }

  // --- Transactions CRUD ---

  Future<int> insertTransaction(TransactionItem item) async {
    if (kIsWeb) {
      _initWebDb();
      final newId = _webDb!.isEmpty
          ? 1
          : (_webDb!.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
      final map = item.toMap();
      map['id'] = newId;
      _webDb!.add(map);
      return newId;
    } else {
      final db = await instance.database;
      return await db.insert('transactions', item.toMap());
    }
  }

  Future<int> updateTransaction(TransactionItem item) async {
    if (kIsWeb) {
      _initWebDb();
      final index = _webDb!.indexWhere((element) => element['id'] == item.id);
      if (index != -1) {
        _webDb![index] = item.toMap();
        _webDb![index]['id'] = item.id;
        return 1;
      }
      return 0;
    } else {
      final db = await instance.database;
      return await db.update(
        'transactions',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
    }
  }

  Future<int> deleteTransaction(int id) async {
    if (kIsWeb) {
      _initWebDb();
      _webDb!.removeWhere((e) => e['parent_id'] == id);
      _webDb!.removeWhere((e) => e['id'] == id);
      return 1;
    } else {
      final db = await instance.database;
      await db.delete('transactions', where: 'parent_id = ?', whereArgs: [id]);
      return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<List<TransactionItem>> getTransactionsForMonth(int year, int month) async {
    final monthStr = month.toString().padLeft(2, '0');
    List<Map<String, dynamic>> allRows;

    if (kIsWeb) {
      _initWebDb();
      final prefix = '$year-$monthStr';
      allRows = _webDb!
          .where((e) => (e['date'] as String).startsWith(prefix))
          .toList();
      allRows.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    } else {
      final db = await instance.database;
      final queryStr = '$year-$monthStr%';
      allRows = await db.query(
        'transactions',
        where: "date LIKE ?",
        whereArgs: [queryStr],
        orderBy: 'date DESC',
      );
    }

    final all = allRows.map((json) => TransactionItem.fromMap(json)).toList();
    final parents = all.where((t) => t.parentId == null).toList();
    final childrenMap = <int, List<TransactionItem>>{};

    for (final child in all.where((t) => t.parentId != null)) {
      childrenMap.putIfAbsent(child.parentId!, () => []).add(child);
    }

    return parents.map((p) {
      final kids = childrenMap[p.id] ?? [];
      return kids.isEmpty ? p : p.copyWith(children: kids);
    }).toList();
  }

  Future<List<MonthlySummary>> getMonthlySummaries() async {
    if (kIsWeb) {
      _initWebDb();
      final Map<String, Map<String, dynamic>> groups = {};

      for (final row in _webDb!) {
        if (row['parent_id'] != null) continue;
        final dateStr = row['date'] as String;
        final y = int.parse(dateStr.substring(0, 4));
        final m = int.parse(dateStr.substring(5, 7));
        final key = '$y-$m';

        if (!groups.containsKey(key)) {
          groups[key] = {'year': y, 'month': m, 'total_income': 0.0, 'total_cost': 0.0};
        }

        final amount = (row['amount'] as num).toDouble();
        if (row['type'] == 'income') {
          groups[key]!['total_income'] = (groups[key]!['total_income'] as double) + amount;
        } else {
          groups[key]!['total_cost'] = (groups[key]!['total_cost'] as double) + amount;
        }
      }

      final list = groups.values.map((row) {
        return MonthlySummary(
          year: row['year'] as int,
          month: row['month'] as int,
          totalIncome: row['total_income'] as double,
          totalCost: row['total_cost'] as double,
        );
      }).toList();

      list.sort((a, b) {
        if (a.year != b.year) return b.year.compareTo(a.year);
        return b.month.compareTo(a.month);
      });

      return list;
    } else {
      final db = await instance.database;
      final result = await db.rawQuery('''
        SELECT
          CAST(SUBSTR(date, 1, 4) AS INTEGER) as year,
          CAST(SUBSTR(date, 6, 2) AS INTEGER) as month,
          SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as total_income,
          SUM(CASE WHEN type = 'cost' THEN amount ELSE 0 END) as total_cost
        FROM transactions
        WHERE parent_id IS NULL
        GROUP BY year, month
        ORDER BY year DESC, month DESC
      ''');

      return result.map((row) {
        return MonthlySummary(
          year: row['year'] as int,
          month: row['month'] as int,
          totalIncome: (row['total_income'] as num?)?.toDouble() ?? 0.0,
          totalCost: (row['total_cost'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    }
  }

  // --- Income Sources CRUD ---

  Future<int> insertIncomeSource(IncomeSource source) async {
    if (kIsWeb) {
      _initWebDb();
      final newId = _webIncomeSources!.isEmpty
          ? 1
          : (_webIncomeSources!.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
      _webIncomeSources!.add({'id': newId, 'name': source.name});
      return newId;
    } else {
      final db = await instance.database;
      return await db.insert('income_sources', source.toMap());
    }
  }

  Future<List<IncomeSource>> getIncomeSources() async {
    if (kIsWeb) {
      _initWebDb();
      return _webIncomeSources!.map((m) => IncomeSource.fromMap(m)).toList();
    } else {
      final db = await instance.database;
      final result = await db.query('income_sources', orderBy: 'name ASC');
      return result.map((m) => IncomeSource.fromMap(m)).toList();
    }
  }

  Future<int> deleteIncomeSource(int id) async {
    if (kIsWeb) {
      _initWebDb();
      _webIncomeSources!.removeWhere((e) => e['id'] == id);
      return 1;
    } else {
      final db = await instance.database;
      return await db.delete('income_sources', where: 'id = ?', whereArgs: [id]);
    }
  }

  // --- Payment Methods CRUD ---

  Future<int> insertPaymentMethod(PaymentMethod method) async {
    if (kIsWeb) {
      _initWebDb();
      final newId = _webPaymentMethods!.isEmpty
          ? 1
          : (_webPaymentMethods!.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
      _webPaymentMethods!.add({'id': newId, 'name': method.name});
      return newId;
    } else {
      final db = await instance.database;
      return await db.insert('payment_methods', method.toMap());
    }
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    if (kIsWeb) {
      _initWebDb();
      return _webPaymentMethods!.map((m) => PaymentMethod.fromMap(m)).toList();
    } else {
      final db = await instance.database;
      final result = await db.query('payment_methods', orderBy: 'name ASC');
      return result.map((m) => PaymentMethod.fromMap(m)).toList();
    }
  }

  Future<int> deletePaymentMethod(int id) async {
    if (kIsWeb) {
      _initWebDb();
      _webPaymentMethods!.removeWhere((e) => e['id'] == id);
      return 1;
    } else {
      final db = await instance.database;
      return await db.delete('payment_methods', where: 'id = ?', whereArgs: [id]);
    }
  }

  // --- Expense Categories (read-only) ---

  Future<List<ExpenseCategory>> getExpenseCategories() async {
    if (kIsWeb) {
      _initWebDb();
      return _webExpenseCategories!.map((m) => ExpenseCategory.fromMap(m)).toList();
    } else {
      final db = await instance.database;
      final result = await db.query('expense_categories', orderBy: 'section ASC, display_name ASC');
      return result.map((m) => ExpenseCategory.fromMap(m)).toList();
    }
  }

  // --- Close ---

  Future<void> close() async {
    if (kIsWeb) return;
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
