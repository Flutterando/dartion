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

class DartIOServer {
  final Config config;
  late HttpServer _server;
  Uuid uuid = const Uuid();

  DartIOServer({required this.config});

  static Future<DartIOServer> getInstance() async {
    return DartIOServer(
      config: await ConfigRepository().getConfig('config.yaml'),
    );
  }

  Future start() async {
    await config.db.init();
    final handler =
        const Pipeline().addMiddleware(logRequests()).addHandler(handleRequest);

    _server = await shelf_io.serve(
      handler,
      InternetAddress.loopbackIPv4,
      config.port,
    );
    stdout.write('Server ${config.name} started...');
    stdout.write('Listening on localhost:${_server.port}');
  }

  // request should be dynamic so the rule is ignored for this line
  // ignore: type_annotate_public_apis
  bool checkFile(request) {
    if (request.uri.pathSegments.length >= 2) {
      return request.uri.pathSegments[request.uri.pathSegments.length - 2] ==
              'file' &&
          config.storage != null;
    }

    return false;
  }

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

  String get getSlash => Platform.isWindows ? r'\' : '/';

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

  Future<Response> handleAuth(Request request) async {
    final token = request.headers[HttpHeaders.authorizationHeader];
    if (token == null) {
      return Response.forbidden(
        jsonEncode({
          'error': 'Not found token Basic',
        }),
      );
    }

    try {
      //@Noslin22 fixes to credentials bug:
      var credentials
          String.fromCharCodes(base64Decode(token.replaceFirst('Basic ', '')))
              .split(':');
      var users = await config.db.getAll('users');
      Map user = users.firstWhere((element) =>
          element['email'] == credentials[0] &&
          element['password'] == credentials[1]);
     
      int index = user.keys.toList().indexOf("password");
      
      List keys = user.keys.toList();
      keys.removeAt(index);
      List values = user.values.toList();
      values.removeAt(index);
      Map newUser = Map.fromIterables(keys, values);

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

  Future<dynamic> getSegment(Request request) async {
    if (request.url.pathSegments.length > 1) {
      return config.db
          .get(request.url.pathSegments.first, request.url.pathSegments[1]);
    } else {
      return config.db.getAll(request.url.pathSegments[0]);
    }
  }

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
