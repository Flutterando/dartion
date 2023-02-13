import 'dart:io';

import 'package:dartion/dartion.dart';

import 'package:dartion/src/templates/templates.dart' as template;

String version = '1.0.5';

void main(List<String> arguments) async {
  final arg = arguments.isEmpty ? '--version' : arguments[0];

  if (arg == 'serve') {
    var server = await DartIOServer.getInstance();
    await server.start();
  } else if (arg == '--version' || arguments[0] == '-v') {
    print('Dartion v$version');
  } else if (arg == 'upgrade') {
    Process.runSync('pub', ['global', 'activate', 'dartion'], runInShell: true);
    print('Upgrated!');
  } else if (arg == 'init') {
    var dir = Directory(arguments.length > 1 ? arguments[1] : '.');

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    print(dir.parent.path);
    if (dir.listSync().isNotEmpty) {
      print('Folder must be empty!');
      return;
    }

    var db = File('${dir.path}/db.json');
    db.createSync(recursive: true);
    db.writeAsStringSync(template.db);

    var config = File('${dir.path}/config.yaml');
    config.createSync(recursive: true);
    config.writeAsStringSync(template.config);

    var index = File('${dir.path}/public/index.html');
    index.createSync(recursive: true);
    index.writeAsStringSync(template.index);
    stdout.write('Dartion configuration has finished!');
    stdout.write('To start, you can now use the command: dartion serve');
  } else {
    exit(0);
  }
}
