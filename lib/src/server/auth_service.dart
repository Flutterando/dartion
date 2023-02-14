import 'package:jaguar_jwt/jaguar_jwt.dart';

class AuthService {
  final String key;
  final int exp;
  final List<String>? aud;
  final List<String>? scape;

  AuthService({
    required this.key,
    required this.exp,
    this.aud,
    this.scape,
  });
  factory AuthService.fromYaml(Map doc) {
    return AuthService(
      key: doc['key'],
      exp: doc['exp'],
      aud: doc['aud'] == null
          ? null
          : (doc['aud'] as List)
              .map<String>(
                (e) => '$e',
              )
              .toList(),
      scape: doc['scape'] == null
          ? []
          : (doc['scape'] as List)
              .map<String>(
                (e) => '$e',
              )
              .toList(),
    );
  }

  String generateToken(int id) {
    final claimSet = JwtClaim(
      subject: '$id',
      issuer: 'dartio',
      maxAge: Duration(seconds: exp),
    );

    return issueJwtHS256(claimSet, key);
  }

  String? isValid(String token, String route) {
    try {
      if (scape?.contains(route) == true) {
        return null;
      }
      final decClaimSet = verifyJwtHS256Signature(token, key);
      decClaimSet.validate(issuer: 'dartio');
      return null;
    } on JwtException catch (e) {
      return e.message;
    }
  }
}
