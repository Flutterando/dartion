import 'dart:io';

import 'package:yaml/yaml.dart';

import 'config_model.dart';

/// Interface class to configure the database server through the yaml file
/// defined in it's method getConfig parameter path (String)
abstract class IConfigRepository {
  /// Gets the database configuration through the yaml file defined in it's
  /// parameter path (String)
  Future<Config> getConfig(String path);
}

/// Class used to configure the database server through the yaml file
/// defined in it's method getConfig parameter path (String)
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
host: 0.0.0.0
''');
    }

    return Config.fromYaml(doc);
  }
}
