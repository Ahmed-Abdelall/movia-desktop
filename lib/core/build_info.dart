abstract final class BuildInfo {
  static const version = '1.2.0';
  static const commit = String.fromEnvironment(
    'MOVIA_COMMIT',
    defaultValue: 'development',
  );
  static const timestamp = String.fromEnvironment(
    'MOVIA_BUILD_TIME',
    defaultValue: 'local build',
  );
  static const type = String.fromEnvironment(
    'MOVIA_BUILD_TYPE',
    defaultValue: 'development',
  );
  static String get shortCommit =>
      commit.length > 8 ? commit.substring(0, 8) : commit;
}
