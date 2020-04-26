import 'dart:convert' show jsonEncode, jsonDecode;
import 'dart:io';

abstract class IDatabase {
  Future save();
  Future<List> getAll(String query);
  Future<Map<String, dynamic>> get(String query, int id);
}

class Database implements IDatabase {
  Map<String, dynamic> _json;
  final String path;

  Database(this.path);

  Future _getJson() async {
    return _json ??= jsonDecode(await File(path).readAsString());
  }

  @override
  Future<List> getAll(String query) async {
    var db = await _getJson();
    return db[query];
  }

  @override
  Future<Map<String, dynamic>> get(String query, int id) async {
    var db = await getAll(query);
    return db.firstWhere((element) => element['id'] == id);
  }

  @override
  Future save() async {
    if (_json != null) {
      await File(path).writeAsString(jsonEncode(_json));
    }
  }
}
