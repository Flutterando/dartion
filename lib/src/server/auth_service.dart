import 'package:jaguar_jwt/jaguar_jwt.dart';

class AuthService {
  /// Auth service key
  final String key;

  /// Auth service expected time to response; Defaults to 3600ms in the
  /// config.yaml created initially
  final int exp;

  /// Auth service aud; Defaults to test.dd in the config.yaml created initially
  final List<String>? aud;
  final List<String>? scape;

  AuthService({
    required this.key,
    required this.exp,
    this.aud,
    this.scape,
  });

  ///Factory constructor to build the AuthService through the config.yaml data
  ///received by a Map parameter
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

  /// Generates an AuthToken based on the integer id provided.
  String generateToken(int id) {
    final claimSet = JwtClaim(
      subject: '$id',
      issuer: 'dartio',
      maxAge: Duration(seconds: exp),
    );

    return issueJwtHS256(claimSet, key);
  }

  /// Uses a try / catch to check the AuthToken validity. Receives a String
  /// token and a String route.
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
