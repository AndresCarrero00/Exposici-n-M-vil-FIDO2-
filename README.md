# Exposición móvil FIDO2

Ejemplo práctico de autenticación sin contraseña mediante **passkeys (FIDO2/WebAuthn)** en una aplicación Flutter.

## Video de la exposición

- [Ver exposición en YouTube](https://youtu.be/EPiZyr5i_qA?si=43Qld3l6ou8ij-3V)

## ¿Qué es FIDO2?

FIDO2 permite iniciar sesión sin enviar una contraseña al servidor. Durante el registro se crea un par de claves:

- La clave privada permanece protegida en el dispositivo y puede requerir huella, Face ID o PIN.
- La clave pública se guarda en el servidor como credencial del usuario.

Durante el inicio de sesión, el servidor entrega un desafío aleatorio. El dispositivo firma ese desafío con la clave privada. El servidor verifica la firma con la clave pública y nunca recibe la clave privada.

Este repositorio incluye una aplicación Flutter educativa con un servidor de confianza simulado en memoria. El servidor simulado permite comprender el flujo, pero no debe usarse en producción.

## Arquitectura del ejemplo

```text
Flutter
  -> solicita opciones de registro o autenticación
  -> passkeys usa Credential Manager / Face ID / huella
  -> devuelve la credencial al backend

Relying Party (backend real)
  -> genera desafíos aleatorios
  -> valida origin/rpId
  -> verifica firmas
  -> almacena claves públicas
```

## Ejecutar la aplicación

Requisitos:

- Flutter SDK 3.41 o superior.
- Android Studio o Xcode.
- Un emulador o dispositivo físico.
- Android 9+ o iOS 16+ recomendado.

```bash
cd flutter_fido2_example
flutter pub get
flutter run
```

Para ejecutar en Android:

```bash
flutter run -d android
```

Para ejecutar en iOS:

```bash
cd ios
pod install
cd ..
flutter run -d ios
```

## Uso del ejemplo

1. Escribe un nombre de usuario.
2. Pulsa **Registrar passkey**.
3. Confirma la operación con la autenticación biométrica del dispositivo.
4. Pulsa **Iniciar sesión con passkey**.
5. El sistema reutiliza la credencial creada para firmar el nuevo desafío.

El nombre de usuario solo identifica la demostración. En producción se debe reemplazar por un identificador seguro proporcionado por el servidor.

## Requisitos de Android e iOS

Para una implementación real:

- Android debe usar HTTPS y declarar el dominio asociado mediante Asset Links.
- iOS debe usar HTTPS y declarar el dominio asociado mediante Apple App Site Association.
- El `rpId` debe coincidir con el dominio registrado.
- El backend debe verificar `clientDataJSON`, `origin`, `challenge`, firma y contador de autenticación.
- Los datos de usuarios y credenciales deben almacenarse en una base de datos, no en memoria.

En un proyecto personal, reemplaza `flutter.corbado.io` por tu propio dominio verificado.

## Contenido de la carpeta

- `flutter_fido2_example/pubspec.yaml`: dependencia Flutter para passkeys.
- `flutter_fido2_example/lib/main.dart`: interfaz y llamadas al autenticador.
- `flutter_fido2_example/lib/local_relying_party_server.dart`: simulación educativa del backend.
