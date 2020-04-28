import 'dart:io';

import '../lib/src/server/dartio_server.dart';
import '../lib/src/templates/templates.dart' as template;

String version = '0.0.7';

void main(List<String> arguments) async {
  if (arguments[0] == 'serve') {
    var server = await DartIOServer.getInstance();
    await server.start();
  } else if (arguments[0] == '--version' || arguments[0] == '-v') {
    print('Dartion v$version');
  } else if (arguments[0] == 'upgrade') {
    Process.runSync('pub', ['global', 'activate', 'dartion'], runInShell: true);
    print('Upgrated!');
  } else if (arguments[0] == 'init') {
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
    print('Finished!');
    print('Use dartio serve!');
  } else {
    exit(0);
  }
}
