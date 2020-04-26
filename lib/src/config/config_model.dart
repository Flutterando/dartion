import 'package:dartio/src/server/auth_service.dart';

import 'database.dart';

class Config {
  final String name;
  final IDatabase db;
  final int port;
  final String statics;
  final AuthService auth;

  Config({this.name, this.db, this.port, this.statics, this.auth});

  factory Config.formYaml(Map doc) {
    return Config(
        name: doc['name'],
        db: Database(doc['db']),
        port: doc['port'],
        statics: doc['statics'],
        auth: doc['auth'] == null ? null : AuthService.formYaml(doc['auth']));
  }
}
