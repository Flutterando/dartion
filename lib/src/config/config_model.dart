import 'package:dartion/src/config/storage.dart';
import 'package:dartion/src/server/auth_service.dart';

import 'database.dart';

class Config {
  final String name;
  final IDatabase db;
  final int port;
  final String? host;
  final String statics;
  final AuthService? auth;
  final Storage? storage;
  final int unauthorizedStatusCode;

  Config({
    this.name = 'Dartion Server',
    required this.db,
    required this.port,
    this.host,
    this.statics = 'public',
    this.auth,
    this.storage,
    this.unauthorizedStatusCode = 403
  });

  factory Config.formYaml(Map doc) {
    return Config(
        name: doc['name'],
        db: Database(doc['db']),
        port: doc['port'],
        host: doc['host'],
        statics: doc['statics'] ?? 'public',
        storage: doc['storage'] == null ? null : Storage.fromYaml(doc['storage']),
        auth: doc['auth'] == null ? null : AuthService.formYaml(doc['auth']),
        unauthorizedStatusCode: doc['unauthorizedStatusCode'] ?? 403);
  }
}
