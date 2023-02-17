/// Class used to mimic the data storage folder; Uses a String folder and a
/// String name in it's constructor.
class Storage {
  /// Storage folder
  final String folder;

  /// Storage name
  final String name;

  /// Storage constructor, requires a folder and a name, both as String params
  Storage({
    required this.folder,
    required this.name,
  });

  /// Factory constructor to build a mock Storage throught the config.yaml data
  factory Storage.fromYaml(Map doc) {
    return Storage(
      folder: doc['folder'],
      name: doc['name'],
    );
  }
}
