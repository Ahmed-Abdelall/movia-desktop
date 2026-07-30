import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const currentVersion = '1.1.0';
const repositoryUrl = 'https://github.com/Ahmed-Abdelall/movia-desktop';
const latestReleaseUrl = '$repositoryUrl/releases/latest';
const releasesApiUrl =
    'https://api.github.com/repos/Ahmed-Abdelall/movia-desktop/releases';

class SemanticVersion implements Comparable<SemanticVersion> {
  const SemanticVersion(this.major, this.minor, this.patch);
  final int major, minor, patch;
  factory SemanticVersion.parse(String value) {
    final match = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)$').firstMatch(value.trim());
    if (match == null) throw const FormatException('Invalid semantic version');
    return SemanticVersion(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }
  @override
  int compareTo(SemanticVersion other) => major != other.major
      ? major.compareTo(other.major)
      : minor != other.minor
      ? minor.compareTo(other.minor)
      : patch.compareTo(other.patch);
  @override
  String toString() => '$major.$minor.$patch';
}

class ReleaseAsset {
  const ReleaseAsset(this.name, this.url, this.size);
  final String name, url;
  final int size;
}

class ReleaseInfo {
  const ReleaseInfo({
    required this.version,
    required this.title,
    required this.notes,
    required this.publishedAt,
    required this.pageUrl,
    required this.installer,
    this.checksum,
  });
  final SemanticVersion version;
  final String title, notes, pageUrl;
  final DateTime publishedAt;
  final ReleaseAsset installer;
  final ReleaseAsset? checksum;

  static ReleaseInfo? fromGitHub(Object? raw, SemanticVersion installed) {
    if (raw is! Map<String, dynamic> ||
        raw['draft'] == true ||
        raw['prerelease'] == true) {
      return null;
    }
    final version = SemanticVersion.parse(raw['tag_name'] as String? ?? '');
    if (version.compareTo(installed) <= 0) return null;
    final assets = (raw['assets'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (a) => ReleaseAsset(
            a['name'] as String? ?? '',
            a['browser_download_url'] as String? ?? '',
            (a['size'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
    final expected = 'Movia-Desktop-Setup-$version.exe';
    final installer = assets
        .where((a) => a.name == expected && _officialAsset(a.url) && a.size > 0)
        .firstOrNull;
    if (installer == null) return null;
    final checksum = assets
        .where(
          (a) =>
              (a.name == '$expected.sha256' || a.name == 'SHA256SUMS.txt') &&
              _officialAsset(a.url),
        )
        .firstOrNull;
    final published = DateTime.tryParse(raw['published_at'] as String? ?? '');
    final page = raw['html_url'] as String? ?? '';
    if (published == null || !page.startsWith('$repositoryUrl/releases/')) {
      return null;
    }
    return ReleaseInfo(
      version: version,
      title: raw['name'] as String? ?? 'Movia Desktop $version',
      notes: raw['body'] as String? ?? '',
      publishedAt: published,
      pageUrl: page,
      installer: installer,
      checksum: checksum,
    );
  }
}

bool _officialAsset(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      uri.scheme == 'https' &&
      (uri.host == 'github.com' ||
          uri.host == 'objects.githubusercontent.com') &&
      (uri.host != 'github.com' ||
          uri.path.startsWith(
            '/Ahmed-Abdelall/movia-desktop/releases/download/',
          ));
}

enum UpdateStatus {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  downloaded,
  installing,
  networkUnavailable,
  apiUnavailable,
  invalidRelease,
  downloadFailed,
  checksumMismatch,
  cancelled,
  installerLaunchFailed,
}

class UpdateResult {
  const UpdateResult(this.status, {this.release, this.message});
  final UpdateStatus status;
  final ReleaseInfo? release;
  final String? message;
}

class UpdateService {
  UpdateService({http.Client? client}) : client = client ?? http.Client();
  final http.Client client;
  Future<UpdateResult> check() async {
    try {
      final response = await client
          .get(
            Uri.parse(releasesApiUrl),
            headers: const {
              'Accept': 'application/vnd.github+json',
              'X-GitHub-Api-Version': '2022-11-28',
              'User-Agent': 'Movia-Desktop/1.1.0',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return UpdateResult(
          UpdateStatus.apiUnavailable,
          message: 'GitHub returned HTTP ${response.statusCode}.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return const UpdateResult(UpdateStatus.invalidRelease);
      }
      final installed = SemanticVersion.parse(currentVersion);
      for (final raw in decoded) {
        try {
          final release = ReleaseInfo.fromGitHub(raw, installed);
          if (release != null) {
            return UpdateResult(UpdateStatus.available, release: release);
          }
        } on FormatException {
          continue;
        }
      }
      return const UpdateResult(UpdateStatus.upToDate);
    } on SocketException {
      return const UpdateResult(UpdateStatus.networkUnavailable);
    } on TimeoutException {
      return const UpdateResult(UpdateStatus.networkUnavailable);
    } on FormatException {
      return const UpdateResult(UpdateStatus.invalidRelease);
    } catch (e) {
      return UpdateResult(UpdateStatus.apiUnavailable, message: '$e');
    }
  }

  Future<File> download(
    ReleaseInfo release,
    void Function(int, int?) progress, {
    bool Function()? cancelled,
  }) async {
    final dir = Directory(
      p.join((await getTemporaryDirectory()).path, 'Movia', 'updates'),
    );
    await dir.create(recursive: true);
    for (final old in dir.listSync().whereType<File>().where(
      (f) => p.basename(f.path).startsWith('Movia-Desktop-Setup-'),
    )) {
      await old.delete();
    }
    final request = http.Request('GET', Uri.parse(release.installer.url))
      ..headers['User-Agent'] = 'Movia-Desktop/1.1.0';
    final response = await client.send(request);
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}');
    }
    final file = File(p.join(dir.path, release.installer.name));
    final sink = file.openWrite();
    var received = 0;
    try {
      await for (final bytes in response.stream) {
        if (cancelled?.call() == true) {
          throw const UpdateCancelled();
        }
        received += bytes.length;
        sink.add(bytes);
        progress(received, response.contentLength);
      }
    } finally {
      await sink.close();
    }
    if (received == 0) {
      await file.delete();
      throw const HttpException('Empty download');
    }
    if (release.checksum != null) {
      final checksumResponse = await client.get(
        Uri.parse(release.checksum!.url),
        headers: const {'User-Agent': 'Movia-Desktop/1.1.0'},
      );
      if (checksumResponse.statusCode != 200) {
        await file.delete();
        throw const FormatException('Checksum unavailable');
      }
      final expected = _checksumFor(
        checksumResponse.body,
        release.installer.name,
      );
      final actual = sha256.convert(await file.readAsBytes()).toString();
      if (expected == null || expected.toLowerCase() != actual) {
        await file.delete();
        throw const ChecksumMismatch();
      }
    }
    return file;
  }

  Future<bool> launchInstaller(File file) async {
    if (!await file.exists() ||
        await file.length() == 0 ||
        p.extension(file.path).toLowerCase() != '.exe') {
      return false;
    }
    final result = await Process.start(file.path, const [
      '/SP-',
      '/CLOSEAPPLICATIONS',
    ], mode: ProcessStartMode.detached);
    return result.pid > 0;
  }
}

String? _checksumFor(String text, String filename) {
  for (final line in const LineSplitter().convert(text)) {
    final match = RegExp(
      r'^([a-fA-F0-9]{64})\s+\*?(.+)$',
    ).firstMatch(line.trim());
    if (match != null && match[2] == filename) return match[1];
  }
  final only = RegExp(r'^[a-fA-F0-9]{64}$').firstMatch(text.trim());
  return only?.group(0);
}

class UpdateCancelled implements Exception {
  const UpdateCancelled();
}

class ChecksumMismatch implements Exception {
  const ChecksumMismatch();
}
