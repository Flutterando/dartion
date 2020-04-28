const String config = '''
name: Test
port: 3031
db: db.json
statics: public/

# storage:
#   folder: storage/
#   name: "file"

# auth:
#   key: dajdi3cdj8jw40jv89cj4uybfg9wh9vcnvb
#   exp: 3600
#   scape:
#     - animals
#     - cities
''';

const String db = '''
{
    "users": [
        {
            "name": "Robert",
            "email": "robert@gmail.com",
            "password": "123"
        },
        {
            "name": "Calls",
            "email": "calls@gmail.com",
            "password": "1234"
        }
    ],
    "products": [
        {
            "id": 0,
            "title": "Flutter 2"
        },
        {
            "id": 1,
            "title": "React Native"
        },
        {
            "title": "Ionic",
            "id": 2
        }
    ],
    "cities": [
        {
            "name": "Manaus",
            "id": 0
        },
        {
            "name": "Fortaleza",
            "id": 1
        },
        {
            "name": "Maringá",
            "id": 2
        },
        {
            "name": "São Paulo",
            "id": 3
        }
    ],
    "animals": [
        {
            "name": "Cachorro",
            "id": 0
        },
        {
            "name": "Gato",
            "id": 1
        },
        {
            "name": "Pato",
            "id": 2
        },
        {
            "name": "Galo",
            "id": 3
        }
    ]
}
''';
const String index = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DartIO</title>
</head>
<body>
    <p>Index principal</p>
</body>
</html>
''';
