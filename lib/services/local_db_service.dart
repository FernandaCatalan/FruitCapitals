import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDBService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    _db = await openDatabase(
      join(await getDatabasesPath(), 'observations.db'),
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE observations(
            id TEXT PRIMARY KEY,
            uid TEXT,
            description TEXT,
            latitude REAL,
            longitude REAL,
            createdAt TEXT,
            photoPaths TEXT,
            isSynced INTEGER DEFAULT 0,
            cuartelId TEXT,
            cuartelNombre TEXT,
            hileraId TEXT,
            numeroHilera INTEGER,
            mataId TEXT,
            numeroMata INTEGER,
            tipo TEXT,
            etapa TEXT,
            conteo INTEGER
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_isSynced ON observations(isSynced)'
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE observations ADD COLUMN cuartelId TEXT');
          await db.execute('ALTER TABLE observations ADD COLUMN cuartelNombre TEXT');
          await db.execute('ALTER TABLE observations ADD COLUMN hileraId TEXT');
          await db.execute('ALTER TABLE observations ADD COLUMN numeroHilera INTEGER');
          await db.execute('ALTER TABLE observations ADD COLUMN mataId TEXT');
          await db.execute('ALTER TABLE observations ADD COLUMN numeroMata INTEGER');
          await db.execute('ALTER TABLE observations ADD COLUMN tipo TEXT');
          await db.execute('ALTER TABLE observations ADD COLUMN etapa TEXT');
          await db.execute('ALTER TABLE observations ADD COLUMN conteo INTEGER');
        }
      },
    );

    return _db!;
  }
}
