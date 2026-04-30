import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sensor_data.dart';

class DatabaseService {
  static Database? _database;

  static const _tableName = 'measurements';

  static const _createTable = '''
    CREATE TABLE $_tableName (
      id TEXT PRIMARY KEY,
      user_id TEXT,
      measured_at TEXT NOT NULL,
      plant_id TEXT NOT NULL,
      sample_method TEXT NOT NULL,
      notes TEXT,
      lat REAL NOT NULL,
      lng REAL NOT NULL,
      ph REAL NOT NULL,
      nitrogen REAL NOT NULL,
      phosphorus REAL NOT NULL,
      potassium REAL NOT NULL,
      moisture REAL NOT NULL,
      temperature REAL NOT NULL,
      ec REAL NOT NULL,
      salinity REAL NOT NULL,
      point_name TEXT
    )
  ''';

  static const _createPlantsTable = '''
    CREATE TABLE plants (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL
    )
  ''';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'soil_sensor.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute(_createTable);
        await db.execute(_createPlantsTable);
        await _seedDefaultPlants(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $_tableName ADD COLUMN point_name TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE $_tableName ADD COLUMN custom_plant TEXT');
        }
        if (oldVersion < 4) {
          await db.execute(_createPlantsTable);
          await _seedDefaultPlants(db);

          try {
            await db.execute('''
              INSERT INTO plants (id, name)
              SELECT DISTINCT custom_plant as id, custom_plant as name
              FROM $_tableName
              WHERE custom_plant IS NOT NULL AND custom_plant != ''
            ''');
          } catch (e) {
            // Ignore if column already refactored
          }

          try {
             await db.execute('ALTER TABLE $_tableName RENAME COLUMN plant_type TO plant_id');
          } catch(e) {
             await db.execute('ALTER TABLE $_tableName ADD COLUMN plant_id TEXT');
             await db.execute('UPDATE $_tableName SET plant_id = plant_type');
          }

          try {
            await db.execute('''
              UPDATE $_tableName
              SET plant_id = custom_plant
              WHERE custom_plant IS NOT NULL AND custom_plant != ''
            ''');
          } catch (e) {
            // Ignore if custom_plant column doesn't exist
          }
        }
      },
    );
  }

  static Future<void> _seedDefaultPlants(Database db) async {
    final batch = db.batch();
    for (var entry in defaultPlants.entries) {
      batch.insert('plants', {
        'id': entry.key,
        'name': entry.value,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  static Future<MeasurementRecord> saveMeasurement({
    required String plantId,
    required SampleMethod sampleMethod,
    String? notes,
    String? pointName,
    required double lat,
    required double lng,
    required double ph,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double moisture,
    required double temperature,
    required double ec,
    required double salinity,
  }) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final measuredAt = DateTime.now().toIso8601String();
    final sampleMethodStr = sampleMethodValues[sampleMethod]!;

    await db.insert(
      _tableName,
      {
        'id': id,
        'measured_at': measuredAt,
        'plant_id': plantId,
        'sample_method': sampleMethodStr,
        'notes': notes,
        'point_name': pointName,
        'lat': lat,
        'lng': lng,
        'ph': ph,
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'moisture': moisture,
        'temperature': temperature,
        'ec': ec,
        'salinity': salinity,
      },
    );

    // Fetch the name for the returned record
    String plantName = plantId;
    try {
      final res = await db.query('plants', columns: ['name'], where: 'id = ?', whereArgs: [plantId]);
      if (res.isNotEmpty) {
        plantName = res.first['name'] as String;
      }
    } catch (_) {
      // Ignore
    }

    return MeasurementRecord(
      id: id,
      measuredAt: DateTime.parse(measuredAt),
      plantId: plantId,
      plantName: plantName,
      sampleMethod: sampleMethod,
      notes: notes,
      pointName: pointName,
      lat: lat,
      lng: lng,
      ph: ph,
      nitrogen: nitrogen,
      phosphorus: phosphorus,
      potassium: potassium,
      moisture: moisture,
      temperature: temperature,
      ec: ec,
      salinity: salinity,
    );
  }

  static Future<List<MeasurementRecord>> getMeasurements({
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (from != null) {
      where += 'measured_at >= ?';
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'measured_at <= ?';
      whereArgs.add(to.toIso8601String());
    }

    final rows = await db.rawQuery('''
      SELECT m.*, p.name as plant_name 
      FROM $_tableName m 
      LEFT JOIN plants p ON m.plant_id = p.id
      ${where.isNotEmpty ? 'WHERE $where' : ''}
      ORDER BY m.measured_at DESC
      ${limit != null ? 'LIMIT $limit' : ''}
      ${offset != null ? 'OFFSET $offset' : ''}
    ''', whereArgs.isNotEmpty ? whereArgs : null);

    return rows.map((row) => _rowToRecord(row)).toList();
  }

  static Future<List<Map<String, dynamic>>> getPlants() async {
    final db = await database;
    return db.query('plants', orderBy: 'rowid DESC');
  }

  static Future<String> addPlant(String name) async {
    final db = await database;
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('plants', {
      'id': id,
      'name': name,
    });
    return id;
  }

  static Future<int> getMeasurementCountByPlant(String plantId) async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE plant_id = ?', [plantId]);
    if (res.isNotEmpty) {
      return (res.first['count'] as int?) ?? 0;
    }
    return 0;
  }


  static Future<void> deletePlant(String id) async {
    final db = await database;
    
    // Note: User allowed deleting default plants.

    // Check if it's in use
    final count = await getMeasurementCountByPlant(id);
    if (count > 0) {
      throw Exception('Cannot delete plant: measurements exist ($count).');
    }

    await db.delete('plants', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteMeasurement(String id) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  static MeasurementRecord _rowToRecord(Map<String, dynamic> row) {
    return MeasurementRecord(
      id: row['id'] as String?,
      userId: row['user_id'] as String?,
      measuredAt: row['measured_at'] != null
          ? DateTime.parse(row['measured_at'] as String)
          : null,
      plantId: row['plant_id'] as String? ?? row['plant_type'] as String? ?? 'unknown',
      plantName: row['plant_name'] as String? ?? 
                 row['custom_plant'] as String? ?? 
                 defaultPlants[row['plant_type'] as String?] ?? 
                 'ไม่ทราบชนิด',
      sampleMethod: sampleMethodFromString(row['sample_method'] as String),
      notes: row['notes'] as String?,
      pointName: row['point_name'] as String?,
      lat: (row['lat'] as num).toDouble(),
      lng: (row['lng'] as num).toDouble(),
      ph: (row['ph'] as num).toDouble(),
      nitrogen: (row['nitrogen'] as num).toDouble(),
      phosphorus: (row['phosphorus'] as num).toDouble(),
      potassium: (row['potassium'] as num).toDouble(),
      moisture: (row['moisture'] as num).toDouble(),
      temperature: (row['temperature'] as num).toDouble(),
      ec: (row['ec'] as num).toDouble(),
      salinity: (row['salinity'] as num).toDouble(),
    );
  }

  static final _random = Random(42);
  static double _r(double min, double max) =>
      min + _random.nextDouble() * (max - min);
  static int _ri(int min, int max) => min + _random.nextInt(max - min + 1);

  static Future<void> seedDummyData({int count = 100}) async {
    final db = await database;
    final now = DateTime.now();
    final batch = db.batch();

    for (int i = 0; i < count; i++) {
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final id = 'seed_${timestamp}_$i';
      final measuredAt = now.subtract(
          Duration(days: _ri(0, 89), hours: _ri(0, 23), minutes: _ri(0, 59)));
      final lat = 13.7 + _random.nextDouble() * 0.5;
      final lng = 100.3 + _random.nextDouble() * 0.5;
      final ph = _r(4.5, 8.5);
      final nitrogen = _r(50, 400);
      final phosphorus = _r(10, 100);
      final potassium = _r(80, 350);
      final moisture = _r(10, 80);
      final temperature = _r(15, 40);
      final ec = _r(0.1, 4.0);
      final salinity = ec * 0.64;

      final sampleMethod =
          SampleMethod.values[_ri(0, SampleMethod.values.length - 1)];

      batch.insert(
        _tableName,
        {
          'id': id,
          'measured_at': measuredAt.toIso8601String(),
          'plant_id': defaultPlants.keys.toList()[_ri(0, defaultPlants.length - 1)],
          'sample_method': sampleMethodValues[sampleMethod]!,
          'point_name': 'จุดทดสอบที่ ${i + 1}',
          if (i % 5 == 0) 'notes': 'ตัวอย่างดินชุดที่ ${i + 1}',
          'lat': lat,
          'lng': lng,
          'ph': ph,
          'nitrogen': nitrogen,
          'phosphorus': phosphorus,
          'potassium': potassium,
          'moisture': moisture,
          'temperature': temperature,
          'ec': ec,
          'salinity': salinity,
        },
      );
    }

    await batch.commit(noResult: true);
  }
}
