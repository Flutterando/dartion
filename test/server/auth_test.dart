import 'dart:io';
import 'package:dartion/src/server/auth_service.dart';
import 'package:test/test.dart';

void main() {
  group('Auth', () {
    test('get token', () async {
      final service = AuthService(
        key: 'dajdi3cdj8jw40jv89cj4uybfg9wh9vcnvb',
        exp: 3600,
        aud: ['test.dd'],
      );
      final token = service.generateToken(2);
      stdout.write(token);
      expect(token, isA<String>());
    });
    test('check token invalid', () async {
      final service = AuthService(
        key: 'dajdi3cdj8jw40jv89cj4uybfg9wh9vcnvb',
        exp: 3600,
        aud: ['test.dd'],
        scape: [],
      );

      expect(
        service.isValid(
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsiYXVkaWVuY2UxLmV4Y'
              'W1wbGUuY29tIiwiYXVkaWVuY2UyLmV4YW1wbGUuY29tIl0sImV4cCI6MTU4Nz'
              'kzMTM2NSwiaWF0IjoxNTg3OTMxMzQ1LCJpc3MiOiJkYXJ0aW8iLCJzdWIiOiI'
              'yIn0.YOcosusO4dg2gEk9SCy5R-fdiTDgoMxzioZ2DkOEpWQ',
          'products',
        ),
        isA<String>(),
      );
    });
    test('check token valid', () async {
      final service = AuthService(
        key: 'dajdi3cdj8jw40jv89cj4uybfg9wh9vcnvb',
        exp: 3600,
        aud: ['test.dd'],
        scape: [],
      );

      final token = service.generateToken(2);
      expect(service.isValid(token, 'products'), null);
    });
    test('check scaped route', () async {
      final service = AuthService(
        key: 'dajdi3cdj8jw40jv89cj4uybfg9wh9vcnvb',
        exp: 3600,
        aud: ['test.dd'],
        scape: ['test'],
      );

      expect(service.isValid('fdsfewfdw', 'test'), null);
    });
  });
}
