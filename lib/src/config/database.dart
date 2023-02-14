import 'dart:convert' show jsonEncode, jsonDecode;
import 'dart:io';

/// Interface class for the Database methods. There are 4 methods:
/// init - to initialize the database
/// save - to save an entry to the database
/// getAll - get all entries from it
/// get - get a single entry
abstract class IDatabase {
  /// Starts the database based on the config.yaml settings defined by you.
  Future init();

  /// Saves an entry to the database. Receives a key as String and a
  /// dynamic by default. The example uses a Map<String, String> (see the Test
  /// folder to understand it). Your implementation of the mock database will
  /// define what to use as values.
  Future save(String key, dynamic seg);

  /// Gets all entries from the defined database based on a String query
  Future<List> getAll(String query);

  /// Gets a single entry from the defined database based on a String query and
  /// a String id
  Future<Map<String, dynamic>> get(String query, String id);
}

/// The class that defines the Database methods.
/// Receives the database json through it's constructor as a String.
/// There are 4 methods in this class:
/// init - to initialize the database
/// save - to save an entry to the database
/// getAll - get all entries from it
/// get - get a single entry
class Database implements IDatabase {
  late Map<String, dynamic> _json;

  /// The defined path for the database file (db.json on the folder where the
  /// server was initialized, by default)
  final String path;

  /// Constructor method for creating a database instance
  Database(this.path);

  @override
  Future init() async {
    final db = File(path);
    if (db.existsSync()) {
      _json = jsonDecode(await db.readAsString());
    } else {
      await db.create(recursive: true);
      await db.writeAsString('{}');
      _json = {};
    }
  }

  @override
  Future<List> getAll(String query) async {
    final db = _json;
    return db[query] ?? [];
  }

  @override
  Future<Map<String, dynamic>> get(String query, String id) async {
    final db = await getAll(query);
    return db.firstWhere((element) => element['id'].toString() == id);
  }

  @override
  Future save(String key, dynamic value) async {
    _json[key].add(value);
    await File(path).writeAsString(jsonEncode(_json));
  }
}
