import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseHelper {
  static const _databaseName = "inspr_db.db";
  static const _databaseVersion = 1;

  static const quotesTable = 'quotes';
  static const settingsTable = 'settings';

  static const columnId = '_id';
  static const columnRemoteId = 'remote_id';
  static const columnQuote = 'quote';
  static const columnFavoriteQuote = 'favorite';
  static const columnAuthor = 'author';
  static const columnSetting = 'setting';
  static const columnSettingValue = 'value';
  static const columnCreatedOn = 'created_on';
  static const columnModifiedOn = 'modified_on';

  // make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // only have a single app-wide reference to the database
  late Database _database;
  Future<Database> get database async {
    // if (_database != null) return _database;
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database;
  }

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    var documentsDirectory = await getDatabasesPath();
    String path = p.join(documentsDirectory, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    try {
      Batch batch = db.batch();
      batch.execute('''
            CREATE TABLE IF NOT EXISTS $quotesTable (
              $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
              $columnRemoteId TEXT NOT NULL,
              $columnFavoriteQuote INTEGER NOT NULL DEFAULT 0,
              $columnQuote TEXT NOT NULL,
              $columnAuthor TEXT NOT NULL,
              $columnCreatedOn INTEGER NOT NULL,
              $columnModifiedOn INTEGER NOT NULL
            )
            ''');
      batch.execute('''
            CREATE TABLE IF NOT EXISTS $settingsTable (
              $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
              $columnSetting TEXT NOT NULL,
              $columnSettingValue TEXT NOT NULL,
              $columnCreatedOn INTEGER NOT NULL,
              $columnModifiedOn INTEGER NOT NULL
            )
            ''');
      await batch.commit();
    } catch (error) {
      print(error);
    }
  }

  // Helper methods

  // Inserts a row in the database where each key in the Map is a column name
  // and the value is the column value. The return value is the id of the
  // inserted row.
  Future<int> insert(Map<String, dynamic> row, String table) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  Future batchInsert(List<dynamic> data, String table) async {
    try {
      Database db = await instance.database;
      Batch batch = db.batch();
      data.forEach((row) {
        batch.insert(table, row);
      });
      await batch.commit();
      //dynamic result = await batch.commit();
      //return result;
    } catch (error) {
      print(error);
    }
  }

  // All of the rows are returned as a list of maps, where each map is
  // a key-value list of columns.
  Future<List<Map<String, dynamic>>> queryAllRows(String table) async {
    Database db = await instance.database;
    return await db.query(table);
  }

  Future<List<Map<String, dynamic>>> queryWhere(
      String table, String column, List<dynamic> whereArguments) async {
    Database db = await instance.database;
    return await db.rawQuery(
        'SELECT * FROM $table WHERE $column = ?', whereArguments);
  }

  // All of the methods (insert, query, update, delete) can also be done using
  // raw SQL commands. This method uses a raw query to give the row count.
  Future<int?> queryRowCount(String table) async {
    //try {
    Database db = await instance.database;
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $table'));
    // } catch (error, stackTrace) {
    //   await sentry.captureException(
    //     exception: error,
    //     stackTrace: stackTrace,
    //   );
    //   return 0;
    // }
  }

  // We are assuming here that the id column in the map is set. The other
  // column values will be used to update the row.
  Future<int> update(Map<String, dynamic> row, String table) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  // Deletes the row specified by the id. The number of affected rows is
  // returned. This should be 1 as long as the row exists.
  Future<int> delete(int id, String table) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }
}
