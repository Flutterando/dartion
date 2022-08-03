import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

import '../../dartion.dart';
import '../config/config_model.dart';
import 'package:shelf_multipart/form_data.dart';

class DartIOServer {
  final Config config;
  late HttpServer _server;
  var uuid = Uuid();

  DartIOServer({required this.config});

  static Future<DartIOServer> getInstance() async {
    return DartIOServer(
      config: await ConfigRepository().getConfig('config.yaml'),
    );
  }

  Future start() async {
    await config.db.init();
    var handler = const Pipeline().addMiddleware(logRequests()).addHandler(handleRequest);
    var host = config.host ?? InternetAddress.loopbackIPv4;

    _server = await shelf_io.serve(handler, host, config.port);
    print('Server ${config.name} started...');
    print('Listening on ${_server.address.host}:${_server.port}');
  }

  bool checkFile(request) {
    if (request.uri.pathSegments.length >= 2) {
      return request.uri.pathSegments[request.uri.pathSegments.length - 2] == 'file' && config.storage != null;
    }

    return false;
  }

  FutureOr<Response> handleRequest(Request request) {
    try {
      var mimeType = request.mimeType;
      final method = request.method.toUpperCase();

      if (method == 'GET') {
        if (request.url.pathSegments.last == config.statics) {
          return createStaticHandler(config.statics, defaultDocument: 'index.html')(request);
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
      } else if (method == 'POST' && mimeType == 'multipart/form-data' && request.url.pathSegments.last == 'storage' && config.storage != null) {
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

  String get getSlash => Platform.isWindows ? '\\' : '/';

  Future<Response> handleUpload(Request request) async {
    if (!middlewareJwt(request)) {
      return responseUnauthorized();
    }

    if (!request.isMultipartForm) {
      return Response(401); // not a multipart request
    }
    await for (final formData in request.multipartFormData.where((event) => event.name == config.storage?.name)) {
      var dir = Directory(config.storage!.folder);
      var name = "${dir.path}storage_${DateTime.now().millisecondsSinceEpoch}.${formData.filename?.split('.').last}";
      final file = File(name);
      if (!file.existsSync()) {
        file.createSync(recursive: true);
      }
      await file.writeAsBytes(await formData.part.readBytes(), mode: FileMode.writeOnly);
      return Response.ok(jsonEncode({
        'url': basename(file.path),
      }));
    }

    return Response.internalServerError();
  }

  Future<Response> handleAuth(Request request) async {
    var token = request.headers[HttpHeaders.authorizationHeader];
    if (token == null) {
      return Response.forbidden(jsonEncode({
        'error': 'Not found token Basic',
      }));
    }

    try {
      var credentials = String.fromCharCodes(base64Decode(token.replaceFirst('Basic ', ''))).split(':');
      var users = await config.db.getAll('users');
      var user = users.firstWhere((element) => element['email'] == credentials[0] && element['password'] == credentials[1]);
      
      if(user != null){
        final userMap = {
          ...(user as Map)
        };
        userMap.remove('password');
        
        return Response.ok(
          jsonEncode({'user': userMap, 'token': config.auth?.generateToken(user['id']), 'exp': config.auth?.exp}),
          headers: {'content-type': 'application/json'},
        );
      }
      
      return Response.forbidden(jsonEncode({'error': 'Forbidden Access'}));
    
    } catch (e) {
      
      return Response.forbidden(jsonEncode({'error': 'Forbidden Access'}));
    }
  }

  bool middlewareJwt(Request request) {
    if (config.auth == null) {
      return true;
    }

    if (request.url.pathSegments.isEmpty || config.auth?.scape?.contains(request.url.pathSegments[0]) == true) {
      return true;
    }

    var header = request.headers[HttpHeaders.authorizationHeader];
    if (header == null) {
      return false;
    }

    var token = header.replaceFirst('Bearer ', '');

    var valid = config.auth?.isValid(token, request.url.pathSegments[0]);

    if (valid != null) {
      return false;
    }

    return true;
  }

  Future<dynamic> getSegment(Request request) async {
    if (request.url.pathSegments.length > 1) {
      return config.db.get(request.url.pathSegments.first, request.url.pathSegments[1]);
    } else {
      return config.db.getAll(request.url.pathSegments[0]);
    }
  }

  Future<Response> handleGet(Request request) async {
    if (!middlewareJwt(request)) {
      return responseUnauthorized();
    }

    try {
      dynamic seg = await getSegment(request);

      if (seg == null) {
        return Response.notFound(jsonEncode({'error': 'Not found'}));
      } else {
        return Response.ok(jsonEncode(seg), headers: {'content-type': 'application/json'});
      }
    } catch (e) {
      return Response.notFound(jsonEncode({'error': 'Internal Error. $e'}));
    }
  }

  Response responseUnauthorized() => Response(
        config.unauthorizedStatusCode,
        body: jsonEncode({'error': 'middlewareJwt'}),
        headers: {
          'content-type': 'application/json'
        }
      );

  Future<Response> handlePost(Request request) async {
    if (!middlewareJwt(request)) {
      return responseUnauthorized();
    }
    try {
      var content = await request.readAsString(); /*2*/
      var data = jsonDecode(content) as Map;
      final key = request.url.pathSegments[0];
      dynamic seg = await config.db.getAll(request.url.pathSegments[0]);

      if (seg == null) {
        return Response.notFound(jsonEncode({'error': 'Not found'}));
      } else {
        data['id'] = uuid.v1();
        seg.add(data);
        await config.db.save(key, seg);
        return Response.ok(jsonEncode(data), headers: {'content-type': 'application/json'});
      }
    } catch (e) {
      return Response.notFound(jsonEncode({'error': 'Internal Error. $e'}));
    }
  }

  Future<Response> handlePut(Request request) async {
    if (!middlewareJwt(request)) {
      return responseUnauthorized();
    }
    try {
      var content = await request.readAsString(); /*2*/
      var data = jsonDecode(content) as Map;
      final key = request.url.pathSegments[0];
      dynamic seg = await config.db.getAll(key);

      if (seg == null) {
        return Response.notFound(jsonEncode({'error': 'Not found'}));
      } else {
        data['id'] = request.url.pathSegments[1];
        var position = (seg as List).indexWhere((element) => element['id'] == request.url.pathSegments[1]);
        data.forEach((key, value) {
          seg[position][key] = value;
        });
        await config.db.save(key, seg);
        return Response.ok(jsonEncode(data), headers: {'content-type': 'application/json'});
      }
    } catch (e) {
      return Response.notFound(jsonEncode({'error': 'Internal Error. $e'}));
    }
  }

  Future<Response> handleDelete(Request request) async {
    if (!middlewareJwt(request)) {
      return responseUnauthorized();
    }
    try {
      final key = request.url.pathSegments[0];
      dynamic seg = await config.db.getAll(key);

      if (seg == null) {
        return Response.notFound(jsonEncode({'error': 'Not found'}));
      } else {
        (seg as List).removeWhere(
          (element) => element['id'] == request.url.pathSegments[1],
        );
        await config.db.save(key, seg);
        return Response.ok(jsonEncode({'data': 'ok!'}), headers: {'content-type': 'application/json'});
      }
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Internal Error'}));
    }
  }

  Future<Response> handlePatch(Request request) async {
    if (!middlewareJwt(request)) {
      return responseUnauthorized();
    }

    try {
      var content = await request.readAsString(); /*2*/
      var data = jsonDecode(content) as Map;
      final key = request.url.pathSegments[0];

      dynamic seg = await config.db.getAll(key);

      if (seg == null) {
        return Response.notFound(jsonEncode({'error': 'Not found'}));
      } else {
        data['id'] = int.parse(request.url.pathSegments[1]);
        var position = (seg as List).indexWhere((element) => element['id'] == int.parse(request.url.pathSegments[1]));

        data.forEach((key, value) {
          seg[position][key] = value;
        });

        await config.db.save(key, seg);
        return Response.ok(jsonEncode(data), headers: {'content-type': 'application/json'});
      }
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Internal Error'}));
    }
  }
}
