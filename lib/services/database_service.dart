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
      point_name TEXT,
      group_id TEXT
    )
  ''';

  static const _createPlantsTable = '''
    CREATE TABLE plants (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL
    )
  ''';

  static const _createPlotsTable = '''
    CREATE TABLE plots (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      created_at TEXT NOT NULL,
      notes TEXT,
      lat REAL,
      lng REAL
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
      version: 7,
      onCreate: (db, version) async {
        await db.execute(_createTable);
        await db.execute(_createPlantsTable);
        await db.execute(_createPlotsTable);
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
        if (oldVersion < 5) {
          try {
            await db.execute('ALTER TABLE $_tableName ADD COLUMN group_id TEXT');
          } catch (e) {
            // Ignore if column already exists
          }
        }
        if (oldVersion < 6) {
          try {
            await db.execute(_createPlotsTable);
            // Migrate existing groups to plots
            await db.execute('''
              INSERT INTO plots (id, name, created_at)
              SELECT group_id, 'แปลง ' || date(MAX(measured_at)), MIN(measured_at)
              FROM $_tableName
              WHERE group_id IS NOT NULL AND group_id != ''
              GROUP BY group_id
            ''');
          } catch (e) {
            // Ignore if already run
          }
        }
        if (oldVersion < 7) {
          try {
            await db.execute('ALTER TABLE plots ADD COLUMN lat REAL');
            await db.execute('ALTER TABLE plots ADD COLUMN lng REAL');
          } catch (e) {
            // Ignore if columns already exist
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
    String? groupId,
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
    // If no groupId provided, this measurement starts its own group
    final effectiveGroupId = groupId ?? id;

    await db.insert(
      _tableName,
      {
        'id': id,
        'measured_at': measuredAt,
        'plant_id': plantId,
        'sample_method': sampleMethodStr,
        'notes': notes,
        'point_name': pointName,
        'group_id': effectiveGroupId,
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
      groupId: effectiveGroupId,
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

  /// Get all measurements with the same group_id, ordered by date ASC (for trend charts).
  static Future<List<MeasurementRecord>> getMeasurementsByGroupId(String groupId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT m.*, p.name as plant_name
      FROM $_tableName m
      LEFT JOIN plants p ON m.plant_id = p.id
      WHERE m.group_id = ?
      ORDER BY m.measured_at ASC
    ''', [groupId]);
    return rows.map((row) => _rowToRecord(row)).toList();
  }

  // ─── Plots ─────────────────────────────────────────────────────────

  static Future<String> createPlot(String name, {String? notes, double? lat, double? lng}) async {
    final db = await database;
    final id = 'plot_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('plots', {
      'id': id,
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
      'notes': notes,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    });
    return id;
  }

  static Future<List<PlotRecord>> getPlots({
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (from != null) {
      where += 'created_at >= ?';
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'created_at <= ?';
      whereArgs.add(to.toIso8601String());
    }

    final plotRows = await db.query(
      'plots',
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    final List<PlotRecord> plots = [];
    final Set<String> knownPlotIds = {};

    for (var row in plotRows) {
      final plotId = row['id'] as String;
      knownPlotIds.add(plotId);
      final measurements = await getMeasurementsByGroupId(plotId);
      
      // Calculate averages safely
      double ph = 0, n = 0, p = 0, k = 0, moist = 0, temp = 0, ec = 0, sal = 0;
      final count = measurements.length;
      if (count > 0) {
        for (var m in measurements) {
          ph += m.ph; n += m.nitrogen; p += m.phosphorus; k += m.potassium;
          moist += m.moisture; temp += m.temperature; ec += m.ec; sal += m.salinity;
        }
      }

      plots.add(PlotRecord(
        id: plotId,
        name: row['name'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        notes: row['notes'] as String?,
        lat: row['lat'] as double?,
        lng: row['lng'] as double?,
        measurements: measurements,
        ph: count > 0 ? ph / count : 0,
        nitrogen: count > 0 ? n / count : 0,
        phosphorus: count > 0 ? p / count : 0,
        potassium: count > 0 ? k / count : 0,
        moisture: count > 0 ? moist / count : 0,
        temperature: count > 0 ? temp / count : 0,
        ec: count > 0 ? ec / count : 0,
        salinity: count > 0 ? sal / count : 0,
      ));
    }

    // ─── Orphaned measurements (group_id not in plots table) ───────────
    // Only load orphans when fetching ALL plots (no limit/offset = not paginated)
    if (limit == null && offset == null) {
      // Find distinct group_ids in measurements that are NOT in plots table
      String orphanDateFilter = '';
      List<dynamic> orphanArgs = [];
      if (from != null) {
        orphanDateFilter = 'AND m.measured_at >= ?';
        orphanArgs.add(from.toIso8601String());
      }

      final orphanRows = await db.rawQuery('''
        SELECT DISTINCT m.group_id
        FROM $_tableName m
        WHERE (m.group_id IS NOT NULL AND m.group_id != '')
          AND m.group_id NOT IN (SELECT id FROM plots)
          $orphanDateFilter
      ''', orphanArgs);

      for (var row in orphanRows) {
        final groupId = row['group_id'] as String;
        if (knownPlotIds.contains(groupId)) continue;

        final measurements = await getMeasurementsByGroupId(groupId);
        if (measurements.isEmpty) continue;

        double ph = 0, n = 0, p = 0, k = 0, moist = 0, temp = 0, ec = 0, sal = 0;
        for (var m in measurements) {
          ph += m.ph; n += m.nitrogen; p += m.phosphorus; k += m.potassium;
          moist += m.moisture; temp += m.temperature; ec += m.ec; sal += m.salinity;
        }
        final count = measurements.length;
        final earliest = measurements.last.measuredAt ?? DateTime.now();

        // Auto-create a plot entry for this orphaned group
        await db.insert('plots', {
          'id': groupId,
          'name': 'แปลง (นำเข้า) ${earliest.day.toString().padLeft(2, '0')}/${earliest.month.toString().padLeft(2, '0')}/${earliest.year}',
          'created_at': earliest.toIso8601String(),
          'notes': null,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        plots.add(PlotRecord(
          id: groupId,
          name: 'แปลง (นำเข้า) ${earliest.day.toString().padLeft(2, '0')}/${earliest.month.toString().padLeft(2, '0')}/${earliest.year}',
          createdAt: earliest,
          notes: null,
          measurements: measurements,
          ph: ph / count,
          nitrogen: n / count,
          phosphorus: p / count,
          potassium: k / count,
          moisture: moist / count,
          temperature: temp / count,
          ec: ec / count,
          salinity: sal / count,
        ));
      }

      // Also handle measurements with NULL group_id
      final nullGroupRows = await db.rawQuery('''
        SELECT * FROM $_tableName m
        LEFT JOIN plants p ON m.plant_id = p.id
        WHERE (m.group_id IS NULL OR m.group_id = '')
          ${from != null ? 'AND m.measured_at >= ?' : ''}
        ORDER BY m.measured_at DESC
      ''', from != null ? [from.toIso8601String()] : []);

      if (nullGroupRows.isNotEmpty) {
        final measurements = nullGroupRows.map((row) => _rowToRecord(row)).toList();

        // Create a single plot for all ungrouped measurements
        final newPlotId = 'orphan_ungrouped';
        final earliest = measurements.last.measuredAt ?? DateTime.now();

        await db.insert('plots', {
          'id': newPlotId,
          'name': 'รายการไม่จัดกลุ่ม',
          'created_at': earliest.toIso8601String(),
          'notes': null,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        // Update measurements to have the new group_id
        await db.rawUpdate('''
          UPDATE $_tableName SET group_id = ? 
          WHERE (group_id IS NULL OR group_id = '')
        ''', [newPlotId]);

        double ph = 0, n = 0, p2 = 0, k = 0, moist = 0, temp = 0, ec = 0, sal = 0;
        for (var m in measurements) {
          ph += m.ph; n += m.nitrogen; p2 += m.phosphorus; k += m.potassium;
          moist += m.moisture; temp += m.temperature; ec += m.ec; sal += m.salinity;
        }
        final count = measurements.length;

        plots.add(PlotRecord(
          id: newPlotId,
          name: 'รายการไม่จัดกลุ่ม',
          createdAt: earliest,
          notes: null,
          measurements: measurements,
          ph: ph / count,
          nitrogen: n / count,
          phosphorus: p2 / count,
          potassium: k / count,
          moisture: moist / count,
          temperature: temp / count,
          ec: ec / count,
          salinity: sal / count,
        ));
      }
    }

    return plots;
  }

  static Future<void> deletePlot(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('plots', where: 'id = ?', whereArgs: [id]);
      await txn.delete(_tableName, where: 'group_id = ?', whereArgs: [id]);
    });
  }

  // ─── Plants ────────────────────────────────────────────────────────

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
      groupId: row['group_id'] as String?,
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

    // Create some measurement groups (10 groups with multiple rounds)
    final groupPoints = <String, String>{};
    for (int g = 0; g < 10; g++) {
      final gid = 'group_${now.microsecondsSinceEpoch}_$g';
      groupPoints[gid] = 'จุดทดสอบที่ ${g + 1}';
    }
    final groupIds = groupPoints.keys.toList();

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

      // Assign ~60% of measurements to groups (multiple rounds), rest standalone
      final String groupId;
      final String pointName;
      if (i % 5 < 3) {
        // Grouped measurement
        final gIdx = i % groupIds.length;
        groupId = groupIds[gIdx];
        pointName = groupPoints[groupId]!;
      } else {
        // Standalone measurement
        groupId = id;
        pointName = 'จุดเดี่ยว #${i + 1}';
      }

      batch.insert(
        _tableName,
        {
          'id': id,
          'measured_at': measuredAt.toIso8601String(),
          'plant_id': defaultPlants.keys.toList()[_ri(0, defaultPlants.length - 1)],
          'sample_method': sampleMethodValues[sampleMethod]!,
          'point_name': pointName,
          'group_id': groupId,
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
