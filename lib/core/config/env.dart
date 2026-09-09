/// Environment file helpers.
abstract final class Env {
  static String fileNameForFlavor(String flavor) {
    switch (flavor) {
      case 'production':
        return '.env.production';
      case 'staging':
        return '.env.staging';
      case 'development':
      default:
        return '.env.development';
    }
  }
}
