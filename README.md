db.json on root folder = Json created by the tests run on tests folder

# Dartion

Dartion is a RESTful mini web server based on JSON.
This is not just a port of the popular **json-server** for Dart as it adds other features like JWT Authentication.

## Goal

Get your backend up in 5 seconds!
This will make it easier for those who take front-end video classes like Flutter and need a server.
From here, just populate the json file and you will have a simple and ready to use database.

## Installation

1. Get the Dart SDK:

https://dart.dev/get-dart

2. Activate Dartion using pub:

```
 dart pub global activate dartion
```

## Commands

**Upgrade**:

Updates Dartion's version:

```
dartion upgrade
```

**Init server**:

Execute this command in an empty folder:

```
dartion init
```

This will create some configuration files for the quick operation of the server.

**Start server**:

This command will boot the server based on the settings in `config.yaml`.

```
dartion serve
```

## Route system

When running Dartion, we have a structure based on RESTful while the data persists in a JSON file in the folder.

```
GET    /products     -> Get all products
GET    /products/1   -> Get one product
POST   /products     -> Add more one product
PUT    /products/1   -> Edit one product
PATCH  /products/1   -> Edit one product
DELETE /products/1   -> Delete one product
```

POST, PUT and PATH requests must have **body** as JSON. It is not necessary to pass the ID as it is always auto incremented.

## File Upload

You can configure Dartion to accept upload files such as images, pdf's, etc...
Adds **storage** properties to config.yaml
```yaml
storage:
  name: "file"
  folder: storage/
```

File uploads work with "Multipart-form", so you can use the name property to **name** your upload.
We can choose which folder the uploaded files will be on the server using the **folder** property.
Then you will have two reserved routes, one to upload files and the other to retrieve those binaries.
```
POST /storage               -> Send files in Multipart-form
GET  /file/:your-file.ext   -> Retrieve file 
```

NOTE: The **/storage** route returns the file name.



## Authetication

You can use JWT Authentication in two steps.

1. Use the **auth** property in your `config.yaml`

```yaml
name: Test
port: 3031
db: db.json
statics: public

auth:
  key: dajdi3cdj8jw40jv89cj4uybfg9wh9vcnvb
  exp: 3600
  escape:
    - animals
    - cities
```

That's enough to protect your routes.
The auth property takes some configuration parameters:

```yaml
key -> To sign your token
exp -> Token expiration time in seconds
escape -> List of routes that will not be affected by token protection
```

2. Login using the **/auth** route:

To retrieve the token you need a credential.
A credential is basically **base64(email:password)**

See an example in Dart:

```dart

String email = "jose@gmail.com";
String password = "123";
String info = "$email:$password";
String encode = base64Encode(info.codeUnits);

String credencials = "Basic $encode";

```

You can now make a GET request to **/auth**, passing the **credentials** in the `authorization` header.

exemple in dart

```dart
// Using the package http

Response response = await http.get(
  'http://localhost:3031/auth',
  headers: {'authorization': credencials},
);
```

This will return the token and some user information.

```json
{
  "user": {
    "name": "Jose",
    "email": "jose@gmail.com"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1ODc5NjQ1MTAsImlhdCI6MTU4Nzk2MDkxMCwiaXNzIjoiZGFydGlvIiwic3ViIjoibnVsbCJ9.5AeEIpYeu04fKINg6e8Ic5fpT0-KyZH8yPLOO6HoLVA",
  "exp": 3600
}
```

That's it! Now, just use the token to access the routes:

```dart
Response response = await http.get(
  'http://localhost:3031/products',
  headers: {'authorization': "Bearer $token"},
);
```

NOTE: When using Authentication, you will need to have a **users** property in your **db.json** with a user list containing at least **email** and **password** in order to access.

## Community

For more details, join our [Telegram Group Flutterando](https://t.me/flutterando)


