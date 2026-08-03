import 'dart:io';

Future<void> setStartWithWindows(bool enabled) async {
  if (!Platform.isWindows) return;
  const key = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
  final result = enabled
      ? await Process.run('reg.exe', [
          'add',
          key,
          '/v',
          'Movia Desktop',
          '/t',
          'REG_SZ',
          '/d',
          '"${Platform.resolvedExecutable}"',
          '/f',
        ])
      : await Process.run('reg.exe', [
          'delete',
          key,
          '/v',
          'Movia Desktop',
          '/f',
        ]);
  if (enabled && result.exitCode != 0) {
    throw ProcessException(
      'reg.exe',
      const [],
      '${result.stderr}',
      result.exitCode,
    );
  }
}
