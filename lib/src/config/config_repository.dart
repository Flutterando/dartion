import 'dart:io';

import 'package:yaml/yaml.dart';

import 'config_model.dart';

abstract class IConfigRepository {
  Future<Config> getConfig(String path);
}

class ConfigRepository implements IConfigRepository {
  @override
  Future<Config> getConfig(String path) async {
    Map doc = loadYaml(await File(path).readAsString());
    return Config.formYaml(doc);
  }
}
