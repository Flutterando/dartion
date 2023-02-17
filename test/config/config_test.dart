import 'package:dartion/src/config/config_model.dart';
import 'package:dartion/src/config/config_repository.dart';
import 'package:dartion/src/config/database.dart';
import 'package:test/test.dart';

void main() {
  late IConfigRepository rep;

  setUp(() {
    rep = ConfigRepository();
  });

  group('Config', () {
    test('get config', () async {
      final config = await rep.getConfig('/server/config.yaml');

      expect(config, isA<Config>());
      expect(config.name, 'Dartion Server');
      expect(config.port, 3031);
    });

    test('get all from db query', () async {
      final config = await rep.getConfig('/server/config.yaml');
      await config.db.init();

      expect(config.db, isA<IDatabase>());

      final products = await config.db.getAll('products');
      expect(products, isA<List>());
    });

    test('get db one item', () async {
      final config = await rep.getConfig('/server/config.yaml');
      await config.db.init();
      expect(config.db, isA<IDatabase>());

      final item = await config.db.get('products', '0');
      expect(item['title'], 'Flutter 2');
    });

    test('save item to db', () async {
      final config = await rep.getConfig('/server/config.yaml');
      await config.db.init();
      expect(config.db, isA<IDatabase>());

      final item = await config.db.get('products', '0');
      item['title'] = 'Flutter 2';
      expect(item['title'], 'Flutter 2');

      await config.db.save('products', {'id': 3, 'title': 'Flutter 3'});
      final config2 = await rep.getConfig('/server/config.yaml');
      await config2.db.init();
      final item2 = await config2.db.get('products', '3');
      expect(item2['title'], 'Flutter 3');
    });
  });
}
