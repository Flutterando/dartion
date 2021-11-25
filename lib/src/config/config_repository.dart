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
''');
    }

    return Config.formYaml(doc);
  }
}
