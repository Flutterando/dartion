import 'dart:convert' show jsonEncode, jsonDecode;
import 'dart:io';

abstract class IDatabase {
  Future init();
  Future save(String key, dynamic seg);
  Future<List> getAll(String query);
  Future<Map<String, dynamic>> get(String query, String id);
}

class Database implements IDatabase {
  late Map<String, dynamic> _json;
  final String path;

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
    var db = _json;
    return db[query] ?? [];
  }

  @override
  Future<Map<String, dynamic>> get(String query, String id) async {
    var db = await getAll(query);
    return db.firstWhere((element) => element['id'] == id);
  }

  @override
  Future save(String key, dynamic seg) async {
    _json[key] = seg;
    await File(path).writeAsString(jsonEncode(_json));
  }
}
