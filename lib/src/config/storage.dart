class Storage {
  final String folder;
  final String name;

  Storage({this.folder, this.name});

  factory Storage.fromYaml(Map doc) {
    return Storage(
      folder: doc['folder'],
      name: doc['name'],
    );
  }
}
