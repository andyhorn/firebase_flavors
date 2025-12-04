import 'dart:io';

import '../../bin/src/utils/file_system.dart';
import '../../bin/src/utils/process_runner.dart';

/// Mock file system for testing.
class MockFileSystem implements FileSystem {
  final Map<String, String> _files = {};
  final Map<String, bool> _directories = {};
  final Map<String, List<FileSystemEntity>> _directoryContents = {};

  void addFile(String path, String content) {
    _files[path] = content;
  }

  void addDirectory(String path) {
    _directories[path] = true;
  }

  void addDirectoryContents(String path, List<FileSystemEntity> contents) {
    _directoryContents[path] = contents;
  }

  @override
  bool fileExists(String path) => _files.containsKey(path);

  @override
  String readFile(String path) {
    if (!_files.containsKey(path)) {
      throw FileSystemException('File not found: $path');
    }
    return _files[path]!;
  }

  @override
  void writeFile(String path, String content) {
    _files[path] = content;
  }

  @override
  bool directoryExists(String path) => _directories[path] ?? false;

  @override
  List<FileSystemEntity> listDirectory(String path, {bool recursive = false}) {
    return _directoryContents[path] ?? [];
  }

  @override
  String getAbsolutePath(String path) => '/absolute/$path';
}

/// Mock process runner for testing.
class MockProcessRunner implements ProcessRunner {
  final Map<String, ProcessResult> _runResults = {};
  final Map<String, Process> _startProcesses = {};
  final Map<String, int> _exitCodes = {};

  void setRunResult(String executable, ProcessResult result) {
    _runResults[executable] = result;
  }

  void setStartProcess(String executable, Process process, {int exitCode = 0}) {
    _startProcesses[executable] = process;
    _exitCodes[executable] = exitCode;
  }

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    final key = executable;
    if (_runResults.containsKey(key)) {
      return _runResults[key]!;
    }
    return ProcessResult(0, 0, '', '');
  }

  @override
  Future<Process> start(
    String executable,
    List<String> arguments, {
    ProcessStartMode mode = ProcessStartMode.normal,
  }) async {
    final key = executable;
    if (_startProcesses.containsKey(key)) {
      return _startProcesses[key]!;
    }
    // Return a mock process
    return _MockProcess(_exitCodes[key] ?? 0);
  }
}

/// Mock process for testing.
class _MockProcess implements Process {
  final int _exitCode;

  _MockProcess(this._exitCode);

  @override
  Future<int> get exitCode => Future.value(_exitCode);

  @override
  Stream<List<int>> get stdout => const Stream.empty();

  @override
  Stream<List<int>> get stderr => const Stream.empty();

  @override
  IOSink get stdin => throw UnimplementedError();

  @override
  int get pid => 12345;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => true;
}
