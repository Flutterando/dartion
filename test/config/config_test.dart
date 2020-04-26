import 'package:dartion/src/config/config_model.dart';
import 'package:dartion/src/config/config_repository.dart';
import 'package:dartion/src/config/database.dart';
import 'package:test/test.dart';

void main() {
  IConfigRepository rep;
  setUpAll(() {
    rep = ConfigRepository();
  });

  group('Config', () {
    test('get config', () async {
      var config = await rep.getConfig('config.yaml');

      expect(config, isA<Config>());
      expect(config.name, 'Test');
      expect(config.port, 3031);
    });
    test('get db all', () async {
      var config = await rep.getConfig('config.yaml');

      expect(config.db, isA<IDatabase>());

      var products = await config.db.getAll('products');
      expect(products, isA<List>());
    });

    test('get db one item', () async {
      var config = await rep.getConfig('config.yaml');
      expect(config.db, isA<IDatabase>());

      var item = await config.db.get('products', 0);
      expect(item['title'], 'Flutter 2');
    });

    // test('save', () async {
    //   var config = await rep.getConfig('config.yaml');
    //   expect(config.db, isA<IDatabase>());

    //   var item = await config.db.get('products', 1);
    //   item['title'] = 'Flutter 2';
    //   expect(item['title'], 'Flutter 2');
    //   await config.db.save();
    //   var config2 = await rep.getConfig('config.yaml');
    //   var item2 = await config2.db.get('products', 1);
    //   expect(item2['title'], 'Flutter 2');
    // });
  });
}
