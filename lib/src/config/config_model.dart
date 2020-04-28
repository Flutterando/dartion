import 'package:dartion/src/config/storage.dart';
import 'package:dartion/src/server/auth_service.dart';

import 'database.dart';

class Config {
  final String name;
  final IDatabase db;
  final int port;
  final String statics;
  final AuthService auth;
  final Storage storage;

  Config(
      {this.name, this.db, this.port, this.statics, this.auth, this.storage});

  factory Config.formYaml(Map doc) {
    return Config(
        name: doc['name'],
        db: Database(doc['db']),
        port: doc['port'],
        statics: doc['statics'],
        storage:
            doc['storage'] == null ? null : Storage.fromYaml(doc['storage']),
        auth: doc['auth'] == null ? null : AuthService.formYaml(doc['auth']));
  }
}
