class Storage {
  final String folder;
  final String name;

  Storage({
    required this.folder,
    required this.name,
  });

  factory Storage.fromYaml(Map doc) {
    return Storage(
      folder: doc['folder'],
      name: doc['name'],
    );
  }
}
