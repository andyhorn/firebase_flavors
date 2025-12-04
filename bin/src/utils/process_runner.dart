import 'dart:io';

/// Abstraction for process execution to enable testing.
abstract class ProcessRunner {
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  });

  Future<Process> start(
    String executable,
    List<String> arguments, {
    ProcessStartMode mode = ProcessStartMode.normal,
  });
}

/// Default implementation using dart:io.
class DefaultProcessRunner implements ProcessRunner {
  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) {
    return Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    );
  }

  @override
  Future<Process> start(
    String executable,
    List<String> arguments, {
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    return Process.start(executable, arguments, mode: mode);
  }
}
