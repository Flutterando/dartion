# Dartion

Dartion is a RESTful mini web server based on JSON.
This is not just a port of the popular **json-server** for dart as it adds other features like JWT authentication.

## Goal

Up your backend in 5 Seconds!
This will make it easier for those who take front-end video classes like Flutter and need a ready server. From here, just populate the json file and you will have a simple and ready to use database.

## Instalation

1. First of all you need install the Dart:

https://dart.dev/get-dart

2. Activate the slidy using the pub:

```dart
 pub global activate dartion
```

## Commands

**Upgrade**:

Updates dartion's version:
```
dartion upgrade
```

**Init server**:

Exec this command in empty folder.
```
dartion init
```
This will create some configuration files for the quick operation of the server.

**Start server**:

This command will boot the server based on the settings in config.yaml.
```
dartion serve
```

## Route system

Just when running Dartion, we already have a structure based on RESTful while the data persists in a .json file in the folder.

```
GET    /products     -> get all Products
GET    /products/1   -> get one product
POST   /products     -> add more one product
PUT    /products/1   -> edit one product
PATCH  /products/1   -> edit one product
DELETE /products/1   -> delete one product
```

POST, PUT and PATH requests must have ** body ** as json. It is not necessary to pass the ID, it is always auto incremented




For more details join our [Telegram Group Flutterando](https://t.me/flutterando)
