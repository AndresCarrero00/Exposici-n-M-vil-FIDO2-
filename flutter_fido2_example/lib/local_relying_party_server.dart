import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

class LocalUser {
  LocalUser({required this.name, required this.id});

  final String name;
  final String id;
  String? credentialId;
}

class LocalRelyingPartyServer {
  static const rpId = kIsWeb ? 'localhost' : 'flutter.corbado.io';

  final Map<String, LocalUser> _users = {};
  final Map<String, LocalUser> _challenges = {};
  final Random _random = Random.secure();

  String startRegistration(String name) {
    if (_users.containsKey(name)) {
      throw Exception('El usuario ya existe. Usa iniciar sesión.');
    }

    final userId = 'user-${_random.nextInt(100000000)}';
    final challenge = _createChallenge();
    _challenges[challenge] = LocalUser(name: name, id: userId);

    return jsonEncode({
      'challenge': challenge,
      'rp': {'name': 'Ejemplo FIDO2 móvil', 'id': rpId},
      'user': {
        'id': base64UrlEncode(userId.codeUnits),
        'name': name,
        'displayName': name,
      },
      'pubKeyCredParams': [
        {'type': 'public-key', 'alg': -7},
        {'type': 'public-key', 'alg': -257},
      ],
      'authenticatorSelection': {
        'residentKey': 'required',
        'userVerification': 'preferred',
      },
      'timeout': 60000,
    });
  }

  void finishRegistration(String responseJson) {
    final response = jsonDecode(responseJson) as Map<String, dynamic>;
    final clientData = _decodeClientData(response);
    final user = _challenges[clientData['challenge']];

    if (user == null) {
      throw Exception('El desafío de registro no es válido.');
    }

    user.credentialId = response['id'] as String;
    _users[user.name] = user;
  }

  String startAuthentication(String name) {
    final user = _users[name];
    if (user == null) {
      throw Exception('Registra el usuario antes de iniciar sesión.');
    }

    final challenge = _createChallenge();
    _challenges[challenge] = user;

    return jsonEncode({
      'challenge': challenge,
      'rpId': rpId,
      'userVerification': 'preferred',
      'timeout': 60000,
      'allowCredentials': [
        {
          'type': 'public-key',
          'id': user.credentialId,
          'transports': ['internal', 'hybrid'],
        },
      ],
    });
  }

  void finishAuthentication(String responseJson) {
    final response = jsonDecode(responseJson) as Map<String, dynamic>;
    final clientData = _decodeClientData(response);
    final user = _challenges[clientData['challenge']];

    if (user == null) {
      throw Exception('El desafío de autenticación no es válido.');
    }
  }

  Map<String, dynamic> _decodeClientData(Map<String, dynamic> response) {
    final responseData = response['response'] as Map<String, dynamic>;
    final encoded = responseData['clientDataJSON'] as String;
    final padded = encoded.padRight(
      encoded.length + ((4 - encoded.length % 4) % 4),
      '=',
    );
    return jsonDecode(
      utf8.decode(base64Url.decode(padded)),
    ) as Map<String, dynamic>;
  }

  String _createChallenge() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}

String base64UrlEncode(List<int> bytes) {
  return base64Url.encode(bytes).replaceAll('=', '');
}
