<a name="readme-top"></a>


<h1 align="center">DARTION</h1>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://pub.dev/packages/dartion">
    <img src="https://raw.githubusercontent.com/Flutterando/dartion/master/readme_assets/logo-dartion.png" alt="Dartion package Logo" width="180">
  </a>

  <p align="center">
    A RESTful mini web server based on JSON.
    <br>
This is not just a port of the popular json-server for Dart, it also adds some more features like JWT Authentication.
    <br>
    <a href="https://pub.dev/documentation/dartion/latest/"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <!-- <a href="https://link para o demo">View Demo</a> -->
    ·
    <a href="https://github.com/flutterando/dartion/issues">Report Bug</a>
    ·
    <a href="https://github.com/flutterando/dartion/issues">Request Feature</a>
  </p>

<br>

<!--  SHIELDS  ---->

[![Version](https://img.shields.io/github/v/release/flutterando/dartion?style=plastic)](https://pub.dev/packages/dartion)
[![Pub Points](https://img.shields.io/pub/points/dartion?label=pub%20points&style=plastic)](https://pub.dev/packages/dartion/score)
[![Flutterando Analysis](https://img.shields.io/badge/style-flutterando__analysis-blueviolet?style=plastic)](https://pub.dev/packages/flutterando_analysis/)

[![Pub Publisher](https://img.shields.io/pub/publisher/dartion?style=plastic)](https://pub.dev/publishers/flutterando.com.br/packages)
</div>


<br>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#about-the-project">About The Project</a></li>
    <li><a href="#sponsors">Sponsors</a></li>
    <li><a href="#getting-started">Getting Started</a></li>
    <li><a href="#how-to-use">How to Use</a></li>
    <li><a href="#features">Features</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgements">Acknowledgements</a></li>
  </ol>
</details>

<br>

<!-- ABOUT THE PROJECT -->
## About The Project

Get your backend up in 5 seconds!
Dartion aims to make it easier for those who take front-end video lessons in languages like Flutter and need a server to implement and test their codes.
Just get the DartSDK, install Dartion, initialize the server and start it, that's all! 
It comes with support to HTTP requests and JWT Authentication.  
After installing, just populate the db.json file and you will have a simple and ready to use database.

<!-- PROJECT EXAMPLE (IMAGE) -->
<!-- <br>
<Center>
<img src="readme_assets/project-readme-example.gif" alt="Dartion package working gif" width="400">
</Center> -->

<br>

<i> This project is distributed under the MIT License. See `LICENSE.txt` for more information.</i>

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- SPONSORS -->
## Sponsors

<a href="https://fteam.dev">
    <img src="https://raw.githubusercontent.com/Flutterando/flutterando-readme-template/master/readme_assets/sponsor-logo.png" alt="Logo" width="120">
  </a>

<p align="right">(<a href="#readme-top">back to top</a>)</p>
<br>


<!-- GETTING STARTED -->
## Getting Started

1. Get the [Dart SDK](https://dart.dev/get-dart)

2. Activate Dartion using pub:

```
 dart pub global activate dartion
```

<br> 

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## How to Use

<br>

### **Commands**

<br>

**Upgrade**:

Updates Dartion's version:

```
dartion upgrade
```

<br>

**Init server**:

Execute the command below in an empty folder, it will create the base configuration files for your server:

```
dartion init
```

<br>

**Start server**:

The command below will boot the server based on the settings configured in the `config.yaml` you have now on your created folder.

```
dartion serve
```

If you want to change those settings, you can edit the `config.yaml` as you like. Refer to the documentation on the init and serve commands, and also the Database class, to know a little bit more about these configurations. 

<br>

### **Route system**

When running Dartion we have a structure based on RESTful, while the data persists in a JSON file in the folder, named by default `db.json`.

```
GET    /products     -> Get all products
GET    /products/1   -> Get one product
POST   /products     -> Add more one product
PUT    /products/1   -> Edit one product
PATCH  /products/1   -> Edit one product
DELETE /products/1   -> Delete one product
```

POST, PUT and PATH requests must have their **body** as JSON. It is not necessary to pass the ID, it is incremented automatically.

<br>

### **File Upload**

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

<br>

### **Authetication**

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

#### NOTE: 
When using Authentication, you will need to have a **users** property in your **db.json** with a user list containing at least **email** and **password** in order to access.

#### NOTE 2: 
The db.json on the root folder of this package was generated by running the tests contained on the `test` folder. 

<br>

_For more details, please refer to the_ [Documentation](https://pub.dev/documentation/dartion/latest/)

<p align="right">(<a href="#readme-top">back to top</a>)</p>




<!-- FEATURES -->
## Features

- ✅ Easy to install and use backend mock server 
- ✅ Database personalization through db.json
- ✅ HTTP request handlers
- ✅ AuthService mock 
- ✅ 

Right now this package has concluded all his intended features. If you have any suggestions or find something to report, see below how to contribute to it. 

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the appropriate tag. 
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

Remember to include a tag, and to follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) and [Semantic Versioning](https://semver.org/) when uploading your commit and/or creating the issue. 

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->
## Contact

Flutterando Community
- [Discord](https://discord.gg/qNBDHNARja)
- [Telegram](https://t.me/flutterando)
- [Website](https://www.flutterando.com.br)
- [Youtube Channel](https://www.youtube.com.br/flutterando)
- [Other useful links](https://linktr.ee/flutterando)


<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGEMENTS -->
## Acknowledgements 

Thank you to all the people who contributed to this project, whitout you this project would not be here today.

<a href="https://github.com/flutterando/dartion/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=flutterando/dartion" />
</a>
<!-- Bot para Lista de contribuidores - https://allcontributors.org/  -->
<!-- Opção (utilizada no momento): https://contrib.rocks/preview?repo=flutterando%2Fasuka -->


<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MANTAINED BY -->
## Maintaned by

<br>

<p align="center">
  <a href="https://www.flutterando.com.br">
    <img width="110px" src="https://raw.githubusercontent.com/Flutterando/flutterando-readme-template/master/readme_assets/logo-flutterando.png">
  </a>
  <p align="center">
    Built and maintained by <a href="https://www.flutterando.com.br">Flutterando</a>.
  </p>
</p>
