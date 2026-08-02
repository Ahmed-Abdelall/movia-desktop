import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum DeploymentMode {
  traditionalInstaller('Traditional Installer'),
  portableInstalled('Portable Installed'),
  standalonePortable('Standalone Portable');

  const DeploymentMode(this.label);
  final String label;
}

class DeploymentInfo {
  const DeploymentInfo({
    required this.mode,
    required this.applicationDirectory,
    required this.dataDirectory,
  });
  final DeploymentMode mode;
  final String applicationDirectory;
  final String dataDirectory;
}

abstract final class DeploymentModeService {
  static DeploymentMode detectFromPaths({
    required String executable,
    required String localAppData,
    bool traditionalInstallerRegistered = false,
  }) {
    final exeDirectory = p.normalize(p.dirname(executable));
    final portableInstalled = p.normalize(
      p.join(localAppData, 'Programs', 'Movia'),
    );
    if (p.equals(exeDirectory, portableInstalled)) {
      return DeploymentMode.portableInstalled;
    }
    return traditionalInstallerRegistered
        ? DeploymentMode.traditionalInstaller
        : DeploymentMode.standalonePortable;
  }

  static Future<DeploymentInfo> current() async {
    final executable = Platform.resolvedExecutable;
    final appDirectory = p.dirname(executable);
    final dataDirectory = (await getApplicationSupportDirectory()).path;
    if (!Platform.isWindows) {
      return DeploymentInfo(
        mode: DeploymentMode.standalonePortable,
        applicationDirectory: appDirectory,
        dataDirectory: dataDirectory,
      );
    }
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    final registered = await _traditionalInstallerMatches(executable);
    return DeploymentInfo(
      mode: detectFromPaths(
        executable: executable,
        localAppData: localAppData,
        traditionalInstallerRegistered: registered,
      ),
      applicationDirectory: appDirectory,
      dataDirectory: dataDirectory,
    );
  }

  static Future<bool> _traditionalInstallerMatches(String executable) async {
    final result = await Process.run('reg.exe', [
      'query',
      r'HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\{51ED7D03-BE63-4EEC-AD43-A91B0AF8D907}_is1',
      '/v',
      'InstallLocation',
    ]);
    if (result.exitCode != 0) return false;
    final location = RegExp(
      r'InstallLocation\s+REG_SZ\s+(.+)',
    ).firstMatch(result.stdout.toString())?.group(1)?.trim();
    return location != null &&
        p.equals(p.join(location, 'movia_desktop.exe'), executable);
  }
}
