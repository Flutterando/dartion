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

POST, PUT and PATH requests must have **body** as json. It is not necessary to pass the ID, it is always auto incremented

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

You can use jwt authentication in two small steps.

1. use the **auth** property in your config.yaml 

```yaml
name: Test
port: 3031
db: db.json
statics: public/

auth:
  key: dajdi3cdj8jw40jv89cj4uybfg9wh9vcnvb
  exp: 3600
  scape:
    - animals
    - cities
```
That's enough to protect your routes.
The auth property has some configuration parameters:
```yaml
key -> to sign your token
exp -> Token expiration time in seconds
scap -> List of routes that will not be affected by token protection

```

2. Login with **/auth** route:

To retrieve the token you need a credential. To retrieve the token you need a credential.
A credential is basically **base64(email:password)**

Veja um exemplo em Dart
```dart

String email = "jose@gmail.com";
String password = "123";
String info = "$email:$password";
String encode = base64Encode(info.codeUnits);

String credencials = "Basic $encode";

```
You can now consume a route **/auth** by passing **credentials** in the header of your request.

exemple in dart
```dart
//using http package

 Response response = await http.get('http://localhost:3031/auth',
      headers: {'authorization': credencials});
```
This will return the Token with some user information.
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
That's right! Now just use the token to access the routes:
```dart
Response response = await http.get('http://localhost:3031/products',
      headers: {'authorization': "Bearer $token"});
```
NOTE: When using Authentication, you will need to have a **users** property in your **db.json** with a user list containing at least **email** and **password** in order to access.

## Community

For more details join our [Telegram Group Flutterando](https://t.me/flutterando)
