import 'package:logger/logger.dart';

Logger? _logger;

/// Initialize the logger with the specified verbosity level.
void initLogger({bool verbose = false}) {
  final level = verbose ? Level.all : Level.info;

  _logger = Logger(
    level: level,
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 3,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
    output: ConsoleOutput(),
    filter: ProductionFilter(),
  );

  logDebug('Logger initialized with verbosity: $verbose');
}

/// Get the logger instance. Returns null if not initialized.
Logger? get logger => _logger;

/// Log an info message.
void logInfo(String message) {
  _logger?.i(message);
}

/// Log a warning message.
void logWarning(String message) {
  _logger?.w(message);
}

/// Log an error message.
void logError(String message, [Object? error, StackTrace? stackTrace]) {
  _logger?.e(message, error: error, stackTrace: stackTrace);
}

/// Log a debug message (only shown in verbose mode).
void logDebug(String message) {
  _logger?.d(message);
}

/// Log a success message.
void logSuccess(String message) {
  _logger?.i('✅ $message');
}
