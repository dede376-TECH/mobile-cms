import 'dart:developer';

class AppLogger {
  static void logInfo(String message) {
    log('INFO: $message');
  }

  static void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    log('ERROR: $message', error: error, stackTrace: stackTrace);
  }

  static void logDebug(String message) {
    log('DEBUG: $message');
  }
}
