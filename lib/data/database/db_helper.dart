import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/transaction_item.dart';
import '../models/monthly_summary.dart';
import '../models/income_source.dart';
import '../models/payment_method.dart';
import '../models/expense_category.dart';
import '../models/installment.dart';
import '../models/savings_confirmation.dart';
import '../models/bank_connection.dart';
import '../models/payment_method_totals.dart';

/// Acceso a la base de datos SQLite. En nativo (Android/iOS/desktop) usa el
/// motor sqflite normal, guardado en el almacenamiento privado de la app. En
/// web usa sqflite_common_ffi_web, que persiste en IndexedDB del navegador
/// (requiere los assets generados por `dart run sqflite_common_ffi_web:setup`
/// en `web/sqlite3.wasm` y `web/sqflite_sw.js`). En ambos casos los datos
/// sobreviven a recargas y cierres de la app/pestaña.
class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  static bool skipSampleSeeding = false;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mis_finanzas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      return await databaseFactoryFfiWeb.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 6,
          onCreate: _createDB,
          onUpgrade: _onUpgrade,
        ),
      );
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 6,
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

    await db.execute(_createInstallmentsTableSql);
    await db.execute(_createSavingsConfirmationsTableSql);
    await db.execute(_createBankConnectionsTableSql);

    if (!skipSampleSeeding) {
      await _seedExpenseCategories(db);
      await _seedDefaultSources(db);
      await _seedSampleTransactions(db);
    }
  }

  static const String _createInstallmentsTableSql = '''
    CREATE TABLE installments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      description TEXT NOT NULL,
      category TEXT NOT NULL,
      payment_method_id INTEGER,
      monthly_amount REAL NOT NULL,
      installment_count INTEGER NOT NULL,
      paid_count INTEGER NOT NULL DEFAULT 0,
      start_year INTEGER NOT NULL,
      start_month INTEGER NOT NULL,
      kind TEXT NOT NULL DEFAULT 'pago',
      FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id)
    )
  ''';

  static const String _createSavingsConfirmationsTableSql = '''
    CREATE TABLE savings_confirmations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      year INTEGER NOT NULL,
      month INTEGER NOT NULL,
      original_amount REAL NOT NULL,
      confirmed_amount REAL NOT NULL,
      confirmed_at TEXT NOT NULL,
      UNIQUE(year, month)
    )
  ''';

  static const String _createBankConnectionsTableSql = '''
    CREATE TABLE bank_connections (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      institution_key TEXT NOT NULL UNIQUE,
      institution_name TEXT NOT NULL,
      institution_type TEXT NOT NULL,
      payment_method_id INTEGER,
      sync_mode TEXT NOT NULL DEFAULT 'manual',
      connected_at TEXT NOT NULL,
      FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id)
    )
  ''';

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

    if (oldVersion < 3) {
      await db.execute(_createInstallmentsTableSql);
    }

    if (oldVersion < 4) {
      await db.execute(_createSavingsConfirmationsTableSql);
    }

    if (oldVersion < 5) {
      await db.execute(_createBankConnectionsTableSql);
    }

    if (oldVersion < 6) {
      await db.execute(
          "ALTER TABLE installments ADD COLUMN kind TEXT NOT NULL DEFAULT 'pago'");
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

  Future<void> _seedDefaultSources(Database db) async {
    await db.insert('income_sources', {'name': 'Sueldo'},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('income_sources', {'name': 'Ventas'},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('payment_methods', {'name': 'Efectivo'},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _seedSampleTransactions(Database db) async {
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

  // --- Transactions CRUD ---

  Future<int> insertTransaction(TransactionItem item) async {
    final db = await instance.database;
    return await db.insert('transactions', item.toMap());
  }

  Future<int> updateTransaction(TransactionItem item) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    await db.delete('transactions', where: 'parent_id = ?', whereArgs: [id]);
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TransactionItem>> getTransactionsForMonth(int year, int month) async {
    final monthStr = month.toString().padLeft(2, '0');
    final db = await instance.database;
    final queryStr = '$year-$monthStr%';
    final allRows = await db.query(
      'transactions',
      where: "date LIKE ?",
      whereArgs: [queryStr],
      orderBy: 'date DESC',
    );

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

  // --- Income Sources CRUD ---

  Future<int> insertIncomeSource(IncomeSource source) async {
    final db = await instance.database;
    return await db.insert('income_sources', source.toMap());
  }

  Future<List<IncomeSource>> getIncomeSources() async {
    final db = await instance.database;
    final result = await db.query('income_sources', orderBy: 'name ASC');
    return result.map((m) => IncomeSource.fromMap(m)).toList();
  }

  Future<int> deleteIncomeSource(int id) async {
    final db = await instance.database;
    return await db.delete('income_sources', where: 'id = ?', whereArgs: [id]);
  }

  // --- Payment Methods CRUD ---

  Future<int> insertPaymentMethod(PaymentMethod method) async {
    final db = await instance.database;
    return await db.insert('payment_methods', method.toMap());
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    final db = await instance.database;
    final result = await db.query('payment_methods', orderBy: 'name ASC');
    return result.map((m) => PaymentMethod.fromMap(m)).toList();
  }

  Future<int> deletePaymentMethod(int id) async {
    final db = await instance.database;
    return await db.delete('payment_methods', where: 'id = ?', whereArgs: [id]);
  }

  // --- Expense Categories CRUD ---

  Future<List<ExpenseCategory>> getExpenseCategories() async {
    final db = await instance.database;
    final result = await db.query('expense_categories', orderBy: 'section ASC, display_name ASC');
    return result.map((m) => ExpenseCategory.fromMap(m)).toList();
  }

  Future<int> insertExpenseCategory(ExpenseCategory category) async {
    final db = await instance.database;
    return await db.insert('expense_categories', category.toMap());
  }

  Future<int> updateExpenseCategory(ExpenseCategory category) async {
    final db = await instance.database;
    return await db.update('expense_categories', category.toMap(),
        where: 'id = ?', whereArgs: [category.id]);
  }

  Future<int> deleteExpenseCategory(int id) async {
    final db = await instance.database;
    return await db.delete('expense_categories', where: 'id = ?', whereArgs: [id]);
  }

  /// ¿Existe ya una categoría con esta key? Útil para garantizar slugs únicos.
  Future<bool> expenseCategoryKeyExists(String key) async {
    final db = await instance.database;
    final rows = await db.query('expense_categories',
        where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isNotEmpty;
  }

  // --- Installments CRUD ---

  Future<List<Installment>> getInstallments() async {
    final db = await instance.database;
    final result = await db.query('installments', orderBy: 'description ASC');
    return result.map((m) => Installment.fromMap(m)).toList();
  }

  Future<int> insertInstallment(Installment installment) async {
    final db = await instance.database;
    return await db.insert('installments', installment.toMap());
  }

  Future<int> updateInstallment(Installment installment) async {
    final db = await instance.database;
    return await db.update('installments', installment.toMap(),
        where: 'id = ?', whereArgs: [installment.id]);
  }

  Future<int> deleteInstallment(int id) async {
    final db = await instance.database;
    return await db.delete('installments', where: 'id = ?', whereArgs: [id]);
  }

  // --- Savings Confirmations CRUD ---

  Future<SavingsConfirmation?> getSavingsConfirmation(int year, int month) async {
    final db = await instance.database;
    final rows = await db.query('savings_confirmations',
        where: 'year = ? AND month = ?', whereArgs: [year, month], limit: 1);
    if (rows.isEmpty) return null;
    return SavingsConfirmation.fromMap(rows.first);
  }

  Future<List<SavingsConfirmation>> getAllSavingsConfirmations() async {
    final db = await instance.database;
    final result = await db.query('savings_confirmations',
        orderBy: 'year ASC, month ASC');
    return result.map((m) => SavingsConfirmation.fromMap(m)).toList();
  }

  Future<int> insertOrUpdateSavingsConfirmation(
      SavingsConfirmation confirmation) async {
    final db = await instance.database;
    return await db.insert('savings_confirmations', confirmation.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Bank Connections CRUD ---

  Future<List<BankConnection>> getBankConnections() async {
    final db = await instance.database;
    final result =
        await db.query('bank_connections', orderBy: 'institution_name ASC');
    return result.map((m) => BankConnection.fromMap(m)).toList();
  }

  Future<int> insertBankConnection(BankConnection connection) async {
    final db = await instance.database;
    return await db.insert('bank_connections', connection.toMap());
  }

  Future<int> deleteBankConnection(int id) async {
    final db = await instance.database;
    return await db.delete('bank_connections', where: 'id = ?', whereArgs: [id]);
  }

  /// Totales históricos de ingresos y gastos agrupados por medio de pago.
  /// Permite medir la actividad de cada institución vinculada.
  Future<Map<int, PaymentMethodTotals>> getPaymentMethodTotals() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT
        payment_method_id,
        SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as total_income,
        SUM(CASE WHEN type = 'cost' THEN amount ELSE 0 END) as total_cost
      FROM transactions
      WHERE parent_id IS NULL AND payment_method_id IS NOT NULL
      GROUP BY payment_method_id
    ''');

    return {
      for (final row in result)
        row['payment_method_id'] as int: PaymentMethodTotals(
          income: (row['total_income'] as num?)?.toDouble() ?? 0.0,
          cost: (row['total_cost'] as num?)?.toDouble() ?? 0.0,
        ),
    };
  }

  /// Totales de ingresos y gastos por medio de pago, desglosados por mes.
  /// Clave externa: 'yyyy-MM'; clave interna: id del medio de pago.
  Future<Map<String, Map<int, PaymentMethodTotals>>>
      getMonthlyPaymentMethodTotals() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT
        SUBSTR(date, 1, 7) as month_key,
        payment_method_id,
        SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as total_income,
        SUM(CASE WHEN type = 'cost' THEN amount ELSE 0 END) as total_cost
      FROM transactions
      WHERE parent_id IS NULL AND payment_method_id IS NOT NULL
      GROUP BY month_key, payment_method_id
    ''');

    final totals = <String, Map<int, PaymentMethodTotals>>{};
    for (final row in result) {
      final monthKey = row['month_key'] as String;
      totals.putIfAbsent(monthKey, () => {})[row['payment_method_id'] as int] =
          PaymentMethodTotals(
        income: (row['total_income'] as num?)?.toDouble() ?? 0.0,
        cost: (row['total_cost'] as num?)?.toDouble() ?? 0.0,
      );
    }
    return totals;
  }

  // --- Close ---

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
