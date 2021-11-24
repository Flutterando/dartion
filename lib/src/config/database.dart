import 'dart:convert' show jsonEncode, jsonDecode;
import 'dart:io';

abstract class IDatabase {
  Future init();
  Future save();
  Future<List> getAll(String query);
  Future<Map<String, dynamic>> get(String query, int id);
}

class Database implements IDatabase {
  late Map<String, dynamic> _json;
  final String path;

  Database(this.path);

  @override
  Future init() async {
    _json = jsonDecode(await File(path).readAsString());
  }

  @override
  Future<List> getAll(String query) async {
    var db = _json;
    return db[query];
  }

  @override
  Future<Map<String, dynamic>> get(String query, int id) async {
    var db = await getAll(query);
    return db.firstWhere((element) => element['id'] == id);
  }

  @override
  Future save() async {
    await File(path).writeAsString(jsonEncode(_json));
  }
}
