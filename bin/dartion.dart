import 'dart:io';

import 'package:dartion/dartion.dart';

import 'package:dartion/src/templates/templates.dart' as template;

String version = '1.1.0';

void main(List<String> arguments) async {
  final arg = arguments.isEmpty ? '--version' : arguments[0];

  if (arg == 'serve') {
    final server = await DartIOServer.getInstance();
    await server.start();
  } else if (arg == '--version' || arguments[0] == '-v') {
    stdout.write('Dartion v$version');
  } else if (arg == 'upgrade') {
    Process.runSync('pub', ['global', 'activate', 'dartion'], runInShell: true);
    stdout.write('Upgrated!');
  } else if (arg == 'init') {
    final dir = Directory(arguments.length > 1 ? arguments[1] : '.');

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    stdout.write(dir.parent.path);
    if (dir.listSync().isNotEmpty) {
      stdout.write('Folder must be empty!');
      return;
    }

    final db = File('${dir.path}/db.json');
    db.createSync(recursive: true);
    db.writeAsStringSync(template.db);

    final config = File('${dir.path}/config.yaml');
    config.createSync(recursive: true);
    config.writeAsStringSync(template.config);

    final index = File('${dir.path}/public/index.html');
    index.createSync(recursive: true);
    index.writeAsStringSync(template.index);
    stdout.write('Dartion initialization finished!');
    stdout.write('You can now use the command: dartion serve');
  } else {
    exit(0);
  }
}
