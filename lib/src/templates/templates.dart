/// Default template for server configurations created by the
/// dartion init command
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
#     - storage
#     - file
''';

/// Default template for a mock database created by the dartion init command
const String db = '''
{
    "users": [
        {
            "id": "0",
            "name": "Robert",
            "email": "robert@gmail.com",
            "password": "123"
        },
        {
            "id": "1",
            "name": "Carls",
            "email": "carls@gmail.com",
            "password": "1234"
        }
    ],
    "products": [
        {
            "id": "0",
            "title": "Flutter 2"
        },
        {
            "id": "1",
            "title": "React Native"
        },
        {
            "title": "Ionic",
            "id": "2"
        }
    ]
}
''';

/// Default Template for the index.html created by the dartion init command
const String index = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DartIO</title>
</head>
<body>
  <Center>
    <p>Dartion is ready for use.</p>
  </Center>
</body>
</html>
''';
