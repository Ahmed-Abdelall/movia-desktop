import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:movia_desktop/features/updates/update_service.dart';
import 'package:movia_desktop/features/updates/deployment_mode.dart';

Map<String, Object?> release({
  String tag = 'v1.2.0',
  bool draft = false,
  bool prerelease = false,
  bool installer = true,
  int size = 123,
  bool portableInstalled = false,
}) => {
  'tag_name': tag,
  'draft': draft,
  'prerelease': prerelease,
  'name': 'Movia Desktop $tag',
  'body': 'Safe notes',
  'published_at': '2026-08-01T10:00:00Z',
  'html_url':
      'https://github.com/Ahmed-Abdelall/movia-desktop/releases/tag/$tag',
  'assets': installer
      ? [
          {
            'name': portableInstalled
                ? 'Movia-Desktop-${tag.substring(1)}-portable-installed.zip'
                : 'Movia-Desktop-Setup-${tag.substring(1)}.exe',
            'browser_download_url':
                'https://github.com/Ahmed-Abdelall/movia-desktop/releases/download/$tag/${portableInstalled ? 'Movia-Desktop-${tag.substring(1)}-portable-installed.zip' : 'Movia-Desktop-Setup-${tag.substring(1)}.exe'}',
            'size': size,
          },
        ]
      : [],
};

void main() {
  test('semantic comparison is numeric, not lexicographic', () {
    expect(
      SemanticVersion.parse('1.10.0').compareTo(SemanticVersion.parse('1.9.0')),
      greaterThan(0),
    );
    expect(
      SemanticVersion.parse('v1.1.0').compareTo(SemanticVersion.parse('1.1.0')),
      0,
    );
    expect(() => SemanticVersion.parse('1.1'), throwsFormatException);
  });
  test('deployment mode detects LocalAppData portable installation', () {
    expect(
      DeploymentModeService.detectFromPaths(
        executable:
            r'C:\Users\Owner\AppData\Local\Programs\Movia\movia_desktop.exe',
        localAppData: r'C:\Users\Owner\AppData\Local',
      ),
      DeploymentMode.portableInstalled,
    );
    expect(
      DeploymentModeService.detectFromPaths(
        executable: r'D:\Portable\Movia\movia_desktop.exe',
        localAppData: r'C:\Users\Owner\AppData\Local',
      ),
      DeploymentMode.standalonePortable,
    );
  });
  test('portable installed mode selects ZIP and not installer', () {
    final info = ReleaseInfo.fromGitHub(
      release(tag: 'v1.3.0', portableInstalled: true),
      SemanticVersion.parse('1.2.0'),
      mode: DeploymentMode.portableInstalled,
    );
    expect(info, isNotNull);
    expect(
      info!.packageAsset.name,
      'Movia-Desktop-1.3.0-portable-installed.zip',
    );
    expect(info.packageAsset.name, isNot(endsWith('.exe')));
  });
  test('drafts and prereleases are rejected for stable', () {
    final installed = SemanticVersion.parse('1.1.0');
    expect(ReleaseInfo.fromGitHub(release(draft: true), installed), isNull);
    expect(
      ReleaseInfo.fromGitHub(release(prerelease: true), installed),
      isNull,
    );
  });
  test('missing, empty, and unofficial installers are rejected', () {
    final installed = SemanticVersion.parse('1.1.0');
    expect(
      ReleaseInfo.fromGitHub(release(installer: false), installed),
      isNull,
    );
    expect(ReleaseInfo.fromGitHub(release(size: 0), installed), isNull);
    final bad = release();
    ((bad['assets'] as List).single as Map)['browser_download_url'] =
        'https://evil.example/update.exe';
    expect(ReleaseInfo.fromGitHub(bad, installed), isNull);
  });
  test(
    'checker skips rejected releases and finds valid newer stable',
    () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode([
            release(tag: 'v2.0.0', draft: true),
            release(tag: 'v1.3.0'),
          ]),
          200,
        ),
      );
      final result = await UpdateService(client: client).check();
      expect(result.status, UpdateStatus.available);
      expect(result.release!.version.toString(), '1.3.0');
    },
  );
  test('checker handles HTTP and malformed JSON failures', () async {
    final unavailable = await UpdateService(
      client: MockClient((_) async => http.Response('', 503)),
    ).check();
    expect(unavailable.status, UpdateStatus.apiUnavailable);
    final invalid = await UpdateService(
      client: MockClient((_) async => http.Response('{', 200)),
    ).check();
    expect(invalid.status, UpdateStatus.invalidRelease);
  });
}
