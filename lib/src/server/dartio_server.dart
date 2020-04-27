import 'dart:convert';
import 'dart:io';

import '../../dartion.dart';
import '../config/config_model.dart';

class DartIOServer {
  final Config config;
  HttpServer _server;

  DartIOServer({this.config});

  static Future<DartIOServer> getInstance() async {
    return DartIOServer(
      config: await ConfigRepository().getConfig('config.yaml'),
    );
  }

  Future start() async {
    _server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      config.port,
    );
    print('Server ${config.name} started...');
    print('Listening on localhost:${_server.port}');

    await for (HttpRequest request in _server) {
      handleRequest(request);
    }
  }

  void handleRequest(HttpRequest request) {
    try {
      var contentType = request.headers.contentType;
      if (request.method == 'GET') {
        if (request.uri.pathSegments.isEmpty) {
          handleHtml(request, 'index.html');
        } else if (request.uri.pathSegments.last.contains('.html')) {
          handleHtml(request, request.uri.pathSegments.join('/'));
        } else if (request.uri.pathSegments.last == 'autheticate') {
          handleAuth(request);
        } else {
          handleGet(request);
        }
      } else if (request.method == 'DELETE') {
        handleDelete(request);
      } else if (request.method == 'POST' &&
          contentType?.mimeType == 'application/json') {
        handlePost(request);
      } else if (request.method == 'PUT' &&
          contentType?.mimeType == 'application/json') {
        handlePut(request);
      } else if (request.method == 'PATCH' &&
          contentType?.mimeType == 'application/json') {
        handlePatch(request);
      } else {
        request.response
          ..statusCode = HttpStatus.methodNotAllowed
          ..write('Unsupported request: ${request.method}.')
          ..close();
      }
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Exception: $e.');
    }
  }

  Future handleAuth(HttpRequest request) async {
    var header = request.headers[HttpHeaders.authorizationHeader];
    if (header == null) {
      request.response
        ..statusCode = HttpStatus.forbidden
        ..write('Not found token Basic');
      await request.response.close();
      return;
    }

    try {
      var credentials = String.fromCharCodes(
              base64Decode(header[0].replaceFirst('Basic ', '')))
          .split(':');
      var users = await config.db.getAll('users');
      var user = users.firstWhere((element) =>
          element['email'] == credentials[0] &&
          element['password'] == credentials[1]);

      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.writeln(jsonEncode({
        'user': user,
        'token': config.auth.generateToken(user['id']),
        'exp': config.auth.exp
      }));
    } catch (e) {
      print(e);
      request.response
        ..statusCode = HttpStatus.forbidden
        ..write('Forbidden Access');
    }
    await request.response.close();
  }

  bool middlewareJwt(HttpRequest request) {
    if (config.auth == null) {
      return true;
    }

    if (request.uri.pathSegments.isEmpty ||
        request.uri.pathSegments.last.contains('.html')) {
      return true;
    }

    var header = request.headers[HttpHeaders.authorizationHeader];
    if (header == null) {
      request.response
        ..statusCode = HttpStatus.forbidden
        ..write('Not found token')
        ..close();
      return false;
    }

    var token = header[0].replaceFirst('Bearer ', '');

    var valid = config.auth.isValid(token, request.uri.pathSegments[0]);

    if (valid != null) {
      request.response
        ..statusCode = HttpStatus.forbidden
        ..write(valid)
        ..close();
      return false;
    }

    return true;
  }

  Future handleHtml(HttpRequest request, String path) async {
    var targetFile = File('${Directory(config.statics).path}/$path');
    if (await targetFile.exists()) {
      request.response.headers.contentType = ContentType.html;
      try {
        await request.response.addStream(targetFile.openRead());
      } catch (e) {
        print("Couldn't read file: $e");
      }
    } else {
      print("Can't open ${targetFile.path}.");
      request.response.statusCode = HttpStatus.notFound;
    }
    await request.response.close();
  }

  Future getSegment(HttpRequest request) async {
    if (request.uri.pathSegments.length > 1) {
      return config.db.get(request.uri.pathSegments[0],
          int.tryParse(request.uri.pathSegments[1]));
    } else {
      return config.db.getAll(request.uri.pathSegments[0]);
    }
  }

  Future handleGet(HttpRequest request) async {
    if (!middlewareJwt(request)) {
      return;
    }
    final response = request.response;

    try {
      dynamic seg = await getSegment(request);

      if (seg == null) {
        response.statusCode = HttpStatus.notFound;
        response.writeln('Not found');
      } else {
        response.statusCode = HttpStatus.ok;
        response.headers.contentType = ContentType.json;
        response.writeln(jsonEncode(seg));
      }
    } catch (e) {
      response.statusCode = HttpStatus.internalServerError;
      response.writeln('Internal Error');
    }
    await response.close();
  }

  Future handlePost(HttpRequest request) async {
    if (!middlewareJwt(request)) {
      return;
    }
    final response = request.response;
    try {
      var content = await utf8.decoder.bind(request).join(); /*2*/
      var data = jsonDecode(content) as Map;
      dynamic seg = await config.db.getAll(request.uri.pathSegments[0]);

      if (seg == null) {
        response.statusCode = HttpStatus.notFound;
        response.writeln('Not found');
      } else {
        response.statusCode = HttpStatus.ok;
        response.headers.contentType = ContentType.json;
        data['id'] = seg.length + 1;
        seg.add(data);
        await config.db.save();
        response.writeln(jsonEncode(data));
      }
    } catch (e) {
      response.statusCode = HttpStatus.internalServerError;
      response.writeln('Internal Error');
    }
    await response.close();
  }

  Future handlePut(HttpRequest request) async {
    if (!middlewareJwt(request)) {
      return;
    }
    final response = request.response;
    try {
      var content = await utf8.decoder.bind(request).join(); /*2*/
      var data = jsonDecode(content) as Map;
      dynamic seg = await config.db.getAll(request.uri.pathSegments[0]);

      if (seg == null) {
        response.statusCode = HttpStatus.notFound;
        response.writeln('Not found');
      } else {
        data['id'] = int.parse(request.uri.pathSegments[1]);
        var position = (seg as List).indexWhere((element) =>
            element['id'] == int.parse(request.uri.pathSegments[1]));
        seg[position] = data;
        await config.db.save();
        response.statusCode = HttpStatus.ok;
        response.headers.contentType = ContentType.json;
        response.writeln(jsonEncode(data));
      }
    } catch (e) {
      response.statusCode = HttpStatus.internalServerError;
      response.writeln('Internal Error');
    }

    await response.close();
  }

  Future handleDelete(HttpRequest request) async {
    if (!middlewareJwt(request)) {
      return;
    }
    final response = request.response;
    try {
      dynamic seg = await config.db.getAll(
        request.uri.pathSegments[0],
      );

      if (seg == null) {
        response.statusCode = HttpStatus.notFound;
        response.writeln('Not found');
      } else {
        (seg as List).removeWhere(
          (element) => element['id'] == int.parse(request.uri.pathSegments[1]),
        );
        response.statusCode = HttpStatus.ok;
        response.headers.contentType = ContentType.json;
        seg = request.uri.pathSegments[1];
        await config.db.save();
        response.writeln(jsonEncode({'data': 'ok!'}));
      }
    } catch (e) {
      response.statusCode = HttpStatus.internalServerError;
      response.writeln('Internal Error');
    }
    await response.close();
  }

  Future handlePatch(HttpRequest request) async {
    if (!middlewareJwt(request)) {
      return;
    }
    final response = request.response;

    try {
      var content = await utf8.decoder.bind(request).join(); /*2*/
      var data = jsonDecode(content) as Map;
      dynamic seg = await config.db.getAll(request.uri.pathSegments[0]);

      if (seg == null) {
        response.statusCode = HttpStatus.notFound;
        response.writeln('Not found');
      } else {
        response.statusCode = HttpStatus.ok;
        response.headers.contentType = ContentType.json;
        data['id'] = int.parse(request.uri.pathSegments[1]);
        var position = (seg as List).indexWhere((element) =>
            element['id'] == int.parse(request.uri.pathSegments[1]));

        data.forEach((key, value) {
          seg[position][key] = value;
        });

        await config.db.save();
        response.writeln(jsonEncode(data));
      }
    } catch (e) {
      response.statusCode = HttpStatus.internalServerError;
      response.writeln('Internal Error');
    }
    await response.close();
  }
}
