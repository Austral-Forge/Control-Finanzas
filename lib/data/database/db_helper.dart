import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction_item.dart';
import '../models/monthly_summary.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  // Base de datos simulada en memoria para la plataforma Web
  static List<Map<String, dynamic>>? _webDb;

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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Datos iniciales para SQLite móvil
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    
    String isoDate(DateTime date, int day) {
      return DateTime(date.year, date.month, day, 12, 0).toIso8601String();
    }

    final initialData = _getInitialData(now, lastMonth, isoDate);
    for (var data in initialData) {
      await db.insert('transactions', data);
    }
  }

  // Helper para inicializar base de datos en la web si es nula
  void _initWebDb() {
    if (_webDb != null) return;
    
    _webDb = [];
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    
    String isoDate(DateTime date, int day) {
      return DateTime(date.year, date.month, day, 12, 0).toIso8601String();
    }

    final initialData = _getInitialData(now, lastMonth, isoDate);
    int idCounter = 1;
    for (var data in initialData) {
      final map = Map<String, dynamic>.from(data);
      map['id'] = idCounter++;
      _webDb!.add(map);
    }
  }

  List<Map<String, dynamic>> _getInitialData(DateTime now, DateTime lastMonth, String Function(DateTime, int) isoDate) {
    return [
      // Mes anterior
      {
        'type': 'income',
        'category': 'sueldo',
        'amount': 2500.0,
        'description': 'Sueldo mensual',
        'date': isoDate(lastMonth, 5),
      },
      {
        'type': 'income',
        'category': 'ventas',
        'amount': 450.0,
        'description': 'Venta de artículos usados',
        'date': isoDate(lastMonth, 15),
      },
      {
        'type': 'income',
        'category': 'pagos_tercero',
        'amount': 150.0,
        'description': 'Reembolso de cena',
        'date': isoDate(lastMonth, 20),
      },
      {
        'type': 'cost',
        'category': 'tarjetas',
        'amount': 600.0,
        'description': 'Tarjeta de Crédito Visa',
        'date': isoDate(lastMonth, 10),
      },
      {
        'type': 'cost',
        'category': 'prestamos',
        'amount': 300.0,
        'description': 'Cuota crédito de consumo',
        'date': isoDate(lastMonth, 12),
      },
      {
        'type': 'cost',
        'category': 'pagos_basicos',
        'amount': 250.0,
        'description': 'Luz, agua e internet',
        'date': isoDate(lastMonth, 5),
      },
      {
        'type': 'cost',
        'category': 'compras',
        'amount': 400.0,
        'description': 'Supermercado mensual',
        'date': isoDate(lastMonth, 8),
      },
      // Mes actual
      {
        'type': 'income',
        'category': 'sueldo',
        'amount': 2500.0,
        'description': 'Sueldo mensual',
        'date': isoDate(now, 5),
      },
      {
        'type': 'cost',
        'category': 'pagos_basicos',
        'amount': 260.0,
        'description': 'Luz, agua y gas',
        'date': isoDate(now, 5),
      },
      {
        'type': 'cost',
        'category': 'compras',
        'amount': 180.0,
        'description': 'Compra supermercado semana 1',
        'date': isoDate(now, 7),
      },
    ];
  }

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
      _webDb!.removeWhere((element) => element['id'] == id);
      return 1;
    } else {
      final db = await instance.database;
      return await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<List<TransactionItem>> getTransactionsForMonth(int year, int month) async {
    if (kIsWeb) {
      _initWebDb();
      final monthStr = month.toString().padLeft(2, '0');
      final prefix = '$year-$monthStr';
      
      final items = _webDb!
          .where((element) => (element['date'] as String).startsWith(prefix))
          .toList();
          
      items.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
      return items.map((json) => TransactionItem.fromMap(json)).toList();
    } else {
      final db = await instance.database;
      final monthStr = month.toString().padLeft(2, '0');
      final queryStr = '$year-$monthStr%';

      final result = await db.query(
        'transactions',
        where: "date LIKE ?",
        whereArgs: [queryStr],
        orderBy: 'date DESC',
      );

      return result.map((json) => TransactionItem.fromMap(json)).toList();
    }
  }

  Future<List<MonthlySummary>> getMonthlySummaries() async {
    if (kIsWeb) {
      _initWebDb();
      final Map<String, Map<String, dynamic>> groups = {};
      
      for (final row in _webDb!) {
        final dateStr = row['date'] as String;
        final year = int.parse(dateStr.substring(0, 4));
        final month = int.parse(dateStr.substring(5, 7));
        final key = '$year-$month';
        
        if (!groups.containsKey(key)) {
          groups[key] = {
            'year': year,
            'month': month,
            'total_income': 0.0,
            'total_cost': 0.0,
          };
        }
        
        final amount = (row['amount'] as num).toDouble();
        if (row['type'] == 'income') {
          groups[key]!['total_income'] = (groups[key]!['total_income'] as double) + amount;
        } else {
          groups[key]!['total_cost'] = (groups[key]!['total_cost'] as double) + amount;
        }
      }
      
      final List<MonthlySummary> list = groups.values.map((row) {
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
        GROUP BY year, month
        ORDER BY year DESC, month DESC
      ''');

      return result.map((row) {
        return MonthlySummary(
          year: row['year'] as int,
          month: row['month'] as int,
          totalIncome: (row['total_income'] as num?)?.toDouble() ?? 0.0,
          totalCost: (row['total_cost'] as num?)?.toDouble() ?? 0.0;
        );
      }).toList();
    }
  }

  Future<void> close() async {
    if (kIsWeb) return;
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
