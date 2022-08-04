import 'dart:io';

import 'package:yaml/yaml.dart';

import 'config_model.dart';

abstract class IConfigRepository {
  Future<Config> getConfig(String path);
}

class ConfigRepository implements IConfigRepository {
  @override
  Future<Config> getConfig(String path) async {
    final yaml = File(path);
    late Map doc;
    if (yaml.existsSync()) {
      doc = loadYaml(await File(path).readAsString());
    } else {
      doc = loadYaml('''
name: Dartion Server
port: 3031
db: db.json

auth:
  key: dajdi3cdj8jw40jv89cj4uybfg9wh9vcnvb
  exp: 3600
  scape:
    - products
''');
    }

    return Config.formYaml(doc);
  }
}
