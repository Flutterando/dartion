import 'package:dartion/src/config/storage.dart';
import 'package:dartion/src/server/auth_service.dart';

import 'database.dart';

/// Class that defines the main parameters of the database, such as
/// ```none
/// name - the database name
/// db - receives an IDatabase object (has methods like init, save...)
/// port - the port for database access
/// statics - receives a String, default is Public
/// auth - receives an AuthService object
/// Storage - receives a Storage object
/// host - receives the ip address of the host
/// ```
class Config {
  /// Database name
  final String name;

  /// IDatabase object
  final IDatabase db;

  /// The hosts port for database access
  final int port;

  /// Database statics, default to Public
  final String statics;

  /// AuthService object
  final AuthService? auth;

  /// Storage object
  final Storage? storage;

  /// Host's IP address
  final String? host;

  /// Class constructor to create the server. Has some default configurations
  /// but it is advised to create a new instance using the factory so you can
  /// implement the configuration set up in your config.yaml file
  Config({
    this.name = 'Dartion Server',
    required this.db,
    required this.port,
    this.statics = 'public',
    this.auth,
    this.storage,
    this.host,
  });

  /// Factory constructor to build your database configuration using a provided
  /// config.yaml file
  /// The config.yaml must have a layout like this one:
  /// ```yaml
  /// name: Test
  /// port: 3031
  /// db: db.json
  /// statics: public
  /// host: 0.0.0.0
  /// auth:
  ///   key: dasdrfgdfvkjbkhvjgfigiuhwiodfuhfiyq
  ///   exp: 3600
  ///   aud: test.dd
  ///   scape:
  ///     - animals
  ///     - cities
  /// ```
  ///
  /// Be aware that the Auth part is created from the Auth.fromYaml factory
  /// so it should have it's contents also ready if you are going to use the
  /// Auth Service in your database.
  factory Config.fromYaml(Map doc) {
    return Config(
      name: doc['name'],
      db: Database(doc['db']),
      port: doc['port'],
      statics: doc['statics'] ?? 'public',
      storage: doc['storage'] == null
          ? null
          : Storage.fromYaml(
              doc['storage'],
            ),
      auth: doc['auth'] == null
          ? null
          : AuthService.fromYaml(
              doc['auth'],
            ),
      host: doc['host'],
    );
  }
}
