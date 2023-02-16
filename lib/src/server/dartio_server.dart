import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_multipart/form_data.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:uuid/uuid.dart';

import '../../dartion.dart';

/// Class that defines the configuration and http server instance
class DartIOServer {
  /// Config class - defines database configuration
  final Config config;

  /// Http Server object from Dart:html. This object class implements a
  /// Stream<HttpRequest>, so treat it accordingly
  late HttpServer _server;

  /// Uuid object from the package Uuid
  Uuid uuid = const Uuid();

  /// DartIoServer construtor class. Requires a config.yaml file.
  DartIOServer({required this.config});

  /// Getter that uses the config.yaml data to return a DartIOServer instance
  static Future<DartIOServer> getInstance() async {
    return DartIOServer(
      config: await ConfigRepository().getConfig('config.yaml'),
    );
  }

  ///Initiates the server using the config.db.init, creating a handler
  ///(middleware) for the requests and starting a shelf server on the localhost
  Future start() async {
    await config.db.init();
    final handler =
        const Pipeline().addMiddleware(logRequests()).addHandler(handleRequest);

    _server = await shelf_io.serve(
      handler,
      config.host ?? InternetAddress.loopbackIPv4,
      config.port,
    );
    stdout.write('Server ${config.name} started...');
    stdout.write('Listening on ${_server.address.host}:${_server.port}');
  }

  ///Method for checking a file. Uses the parameter request, but it's **NOT** a
  ///Shelf package request. It uses a dynamic parameter to get a
  ///uri.pathSegments
  bool checkFile(dynamic request) {
    if (request.uri.pathSegments.length >= 2) {
      return request.uri.pathSegments[request.uri.pathSegments.length - 2] ==
              'file' &&
          config.storage != null;
    }
    return false;
  }

  /// Main method to handle the Requests. Requires a http Request (from the
  /// Shelf package) and based on the method requested calls the appropriate
  /// function.
  FutureOr<Response> handleRequest(Request request) {
    try {
      final mimeType = request.mimeType;
      final method = request.method.toUpperCase();

      if (method == 'GET') {
        if (request.url.pathSegments.last == config.statics) {
          return createStaticHandler(
            config.statics,
            defaultDocument: 'index.html',
          )(request);
        } else if (request.url.pathSegments.last == config.storage?.folder) {
          return createStaticHandler(config.storage!.folder)(request);
        } else if (request.url.pathSegments.last == 'auth') {
          return handleAuth(request);
        } else {
          return handleGet(request);
        }
      } else if (method == 'DELETE') {
        return handleDelete(request);
      } else if (method == 'POST' && mimeType == 'application/json') {
        return handlePost(request);
      } else if (method == 'POST' &&
          mimeType == 'multipart/form-data' &&
          request.url.pathSegments.last == 'storage' &&
          config.storage != null) {
        return handleUpload(request);
      } else if (method == 'PUT' && mimeType == 'application/json') {
        return handlePut(request);
      } else if (method == 'PATCH' && mimeType == 'application/json') {
        return handlePatch(request);
      } else {
        final body = jsonEncode({
          'error': 'Unsupported request: ${request.method}.',
        });
        return Response(HttpStatus.methodNotAllowed, body: body);
      }
    } catch (e) {
      final body = jsonEncode({
        'error': 'Exception: $e.',
      });
      return Response(HttpStatus.internalServerError, body: body);
    }
  }

  ///Getter used to change "\" to "/" in paths if Windows is the platform.
  String get getSlash => Platform.isWindows ? r'\' : '/';

  /// Handles Uploads. Requires a http Request (from the Shelf package).
  Future<Response> handleUpload(Request request) async {
    if (!middlewareJwt(request)) {
      return Response.forbidden(jsonEncode({'error': 'middlewareJwt'}));
    }

    if (!request.isMultipartForm) {
      return Response(401); // not a multipart request
    }
    await for (final formData in request.multipartFormData
        .where((event) => event.name == config.storage?.name)) {
      final dir = Directory(config.storage!.folder);
      final name = '${dir.path}storage_${DateTime.now().millisecondsSinceEpoch}'
          '.${formData.filename?.split('.').last}';
      final file = File(name);
      if (!file.existsSync()) {
        file.createSync(recursive: true);
      }
      await file.writeAsBytes(
        await formData.part.readBytes(),
        mode: FileMode.writeOnly,
      );
      return Response.ok(
        jsonEncode({
          'url': basename(file.path),
        }),
      );
    }

    return Response.internalServerError();
  }

  /// Handles Authorizations. Requires a http Request (from the Shelf package).
  /// The user must use an email and a password, and if the response is ok it
  /// returns an user, a token and an exp fields.
  Future<Response> handleAuth(Request request) async {
    final token = request.headers[HttpHeaders.authorizationHeader];
    if (token == null) {
      return Response.forbidden(
        jsonEncode({
          'error': 'Basic token not found.',
        }),
      );
    }

    //@Noslin22 fixes to credentials bug:
    try {
      final credentials =
          String.fromCharCodes(base64Decode(token.replaceFirst('Basic ', '')))
              .split(':');
      final users = await config.db.getAll('users');
      final Map user = users.firstWhere(
        (element) =>
            element['email'] == credentials[0] &&
            element['password'] == credentials[1],
      );

      final index = user.keys.toList().indexOf('password');

      final keys = user.keys.toList();
      keys.removeAt(index);
      final values = user.values.toList();
      values.removeAt(index);
      final newUser = Map.fromIterables(keys, values);

      return Response.ok(
        jsonEncode({
          'user': newUser,
          'token': config.auth?.generateToken(user['id']),
          'exp': config.auth?.exp
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.forbidden(jsonEncode({'error': 'Forbidden Access'}));
    }
  }
  //end of @Noslin22 fixes

  /// Contains the logic used to validate a Jason Web Token
  bool middlewareJwt(Request request) {
    if (config.auth == null) {
      return true;
    }

    if (request.url.pathSegments.isEmpty ||
        config.auth?.scape?.contains(request.url.pathSegments[0]) == true) {
      return true;
    }

    final header = request.headers[HttpHeaders.authorizationHeader];
    if (header == null) {
      return false;
    }

    final token = header[0].replaceFirst('Bearer ', '');

    final valid = config.auth?.isValid(token, request.url.pathSegments[0]);

    if (valid != null) {
      return false;
    }

    return true;
  }

  /// Gets a segment of the requested url. Requires a http Request (from the
  /// Shelf package).
  Future<dynamic> getSegment(Request request) async {
    if (request.url.pathSegments.length > 1) {
      return config.db
          .get(request.url.pathSegments.first, request.url.pathSegments[1]);
    } else {
      return config.db.getAll(request.url.pathSegments[0]);
    }
  }

  /// Handles Get http requisitions. Requires a http Request (from the Shelf
  /// package).
  Future<Response> handleGet(Request request) async {
    if (!middlewareJwt(request)) {
      return Response.forbidden(jsonEncode({'error': 'middlewareJwt'}));
    }

    try {
      final dynamic seg = await getSegment(request);

      if (seg == null) {
        return Response.notFound(jsonEncode({'error': 'Not found'}));
      } else {
        return Response.ok(
          jsonEncode(seg),
          headers: {'content-type': 'application/json'},
        );
      }
    } catch (e) {
      return Response.notFound(jsonEncode({'error': 'Internal Error. $e'}));
    }
  }

  /// Handles Post http requisitions. Requires a http Request (from the Shelf
  /// package).
  Future<Response> handlePost(Request request) async {
    if (!middlewareJwt(request)) {
      return Response.forbidden(jsonEncode({'error': 'middlewareJwt'}));
    }
    try {
      final content = await request.readAsString(); /*2*/
      final data = jsonDecode(content) as Map;
      final key = request.url.pathSegments[0];
      final dynamic seg = await config.db.getAll(request.url.pathSegments[0]);

      if (seg == null) {
        return Response.notFound(jsonEncode({'error': 'Not found'}));
      } else {
        data['id'] = uuid.v1();
        seg.add(data);
        await config.db.save(key, seg);
        return Response.ok(
          jsonEncode(data),
          headers: {'content-type': 'application/json'},
        );
      }
    } catch (e) {
      return Response.notFound(jsonEncode({'error': 'Internal Error. $e'}));
    }
  }

  /// Handles Put http requisitions. Requires a http Request (from the Shelf
  /// package).
  Future<Response> handlePut(Request request) async {
    if (!middlewareJwt(request)) {
      return Response.forbidden(jsonEncode({'error': 'middlewareJwt'}));
    }
    try {
      final content = await request.readAsString(); /*2*/
      final data = jsonDecode(content) as Map;
      final key = request.url.pathSegments[0];
      final dynamic seg = await config.db.getAll(key);

      if (seg == null) {
        return Response.notFound(jsonEncode({'error': 'Not found'}));
      } else {
        data['id'] = request.url.pathSegments[1];
        final position = (seg as List).indexWhere(
          (element) => element['id'] == request.url.pathSegments[1],
        );
        data.forEach((key, value) {
          seg[position][key] = value;
        });
        await config.db.save(key, seg);
        return Response.ok(
          jsonEncode(data),
          headers: {'content-type': 'application/json'},
        );
      }
    } catch (e) {
      return Response.notFound(jsonEncode({'error': 'Internal Error. $e'}));
    }
  }

  /// Handles Delete http requisitions. Requires a http Request (from the Shelf
  /// package).
  Future<Response> handleDelete(Request request) async {
    if (!middlewareJwt(request)) {
      return Response.forbidden(jsonEncode({'error': 'middlewareJwt'}));
    }
    try {
      final key = request.url.pathSegments[0];
      final dynamic seg = await config.db.getAll(key);

      if (seg == null) {
        return Response.notFound(jsonEncode({'error': 'Not found'}));
      } else {
        (seg as List).removeWhere(
          (element) => element['id'] == request.url.pathSegments[1],
        );
        await config.db.save(key, seg);
        return Response.ok(
          jsonEncode({'data': 'ok!'}),
          headers: {'content-type': 'application/json'},
        );
      }
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal Error'}),
      );
    }
  }

  /// Handles Patch http requisitions. Requires a http Request (from the Shelf
  /// package).
  Future<Response> handlePatch(Request request) async {
    if (!middlewareJwt(request)) {
      return Response.forbidden(jsonEncode({'error': 'middlewareJwt'}));
    }

    try {
      final content = await request.readAsString(); /*2*/
      final data = jsonDecode(content) as Map;
      final key = request.url.pathSegments[0];
      final dynamic seg = await config.db.getAll(key);

      if (seg == null) {
        return Response.notFound(jsonEncode({'error': 'Not found'}));
      } else {
        data['id'] = int.parse(request.url.pathSegments[1]);
        final position = (seg as List).indexWhere(
          (element) => element['id'] == int.parse(request.url.pathSegments[1]),
        );

        data.forEach((key, value) {
          seg[position][key] = value;
        });

        await config.db.save(key, seg);
        return Response.ok(
          jsonEncode(data),
          headers: {'content-type': 'application/json'},
        );
      }
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal Error'}),
      );
    }
  }
}
