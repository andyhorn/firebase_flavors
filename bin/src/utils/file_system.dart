import 'dart:io';

/// Abstraction for file system operations to enable testing.
abstract class FileSystem {
  bool fileExists(String path);
  String readFile(String path);
  void writeFile(String path, String content);
  bool directoryExists(String path);
  List<FileSystemEntity> listDirectory(String path, {bool recursive = false});
  String getAbsolutePath(String path);
}

/// Default implementation using dart:io.
class DefaultFileSystem implements FileSystem {
  @override
  bool fileExists(String path) => File(path).existsSync();

  @override
  String readFile(String path) => File(path).readAsStringSync();

  @override
  void writeFile(String path, String content) {
    File(path).writeAsStringSync(content);
  }

  @override
  bool directoryExists(String path) => Directory(path).existsSync();

  @override
  List<FileSystemEntity> listDirectory(String path, {bool recursive = false}) {
    return Directory(path).listSync(recursive: recursive);
  }

  @override
  String getAbsolutePath(String path) => File(path).absolute.path;
}
