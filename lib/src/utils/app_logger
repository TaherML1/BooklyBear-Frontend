import 'package:logger/logger.dart';

class AppLogger {
  static const _prefix = 'MYAPP';

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  static void info(String message) => _logger.i('$_prefix: $message');
  static void warn(String message) => _logger.w('$_prefix: $message');
  static void error(String message) => _logger.e('$_prefix: $message');
  static void debug(String message) => _logger.d('$_prefix: $message');
}






