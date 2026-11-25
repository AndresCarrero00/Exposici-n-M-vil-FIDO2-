import 'package:flutter/material.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

import 'local_relying_party_server.dart';

void main() {
  runApp(const Fido2ExampleApp());
}

class Fido2ExampleApp extends StatelessWidget {
  const Fido2ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ejemplo FIDO2',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const Fido2Page(),
    );
  }
}

class Fido2Page extends StatefulWidget {
  const Fido2Page({super.key});

  @override
  State<Fido2Page> createState() => _Fido2PageState();
}

class _Fido2PageState extends State<Fido2Page> {
  final _nameController = TextEditingController();
  final _server = LocalRelyingPartyServer();
  final _authenticator = PasskeyAuthenticator(debugMode: true);
  String _status = 'Listo';
  bool _loading = false;

  Future<void> _register() async {
    await _runFlow(() async {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        throw Exception('Escribe un nombre de usuario.');
      }

      final challenge = _server.startRegistration(name);
      final request = RegisterRequestType.fromJsonString(challenge);
      final credential = await _authenticator.register(request);

      _server.finishRegistration(credential.toJsonString());
      return 'Passkey registrada para $name';
    });
  }

  Future<void> _authenticate() async {
    await _runFlow(() async {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        throw Exception('Escribe un nombre de usuario.');
      }

      final challenge = _server.startAuthentication(name);
      final request = AuthenticateRequestType.fromJsonString(challenge);
      final credential = await _authenticator.authenticate(request);

      _server.finishAuthentication(credential.toJsonString());
      return 'Sesión iniciada para $name';
    });
  }

  Future<void> _runFlow(Future<String> Function() flow) async {
    setState(() {
      _loading = true;
      _status = 'Procesando...';
    });

    try {
      final message = await flow();
      setState(() => _status = message);
    } catch (error) {
      setState(() => _status = 'Error: $error');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FIDO2 / Passkeys')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fingerprint, size: 72),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de usuario',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _register,
                      child: const Text('Registrar passkey'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _authenticate,
                      child: const Text('Iniciar sesión con passkey'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_loading) const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(_status, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
