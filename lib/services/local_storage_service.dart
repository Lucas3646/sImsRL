import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:simsrl/models/garment.dart';
import 'package:simsrl/models/outfit.dart';
import 'package:simsrl/models/user_profile.dart';

class LocalSnapshot {
  const LocalSnapshot({
    required this.onboardingComplete,
    required this.demoMode,
    required this.garments,
    required this.outfits,
    this.profile,
  });

  final bool onboardingComplete;
  final bool demoMode;
  final UserProfile? profile;
  final List<Garment> garments;
  final List<Outfit> outfits;
}

class LocalStorageService {
  static const _dataFileName = 'simsrl_data.json';

  Future<Directory> _appDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/simsrl');
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<File> _dataFile() async {
    final directory = await _appDirectory();
    return File('${directory.path}/$_dataFileName');
  }

  Future<String> persistImage(
    String sourcePath, {
    required String prefix,
  }) async {
    final source = File(sourcePath);
    if (!source.existsSync()) {
      throw const FileSystemException('Le fichier image est introuvable.');
    }
    final directory = await _appDirectory();
    final extension = sourcePath.contains('.')
        ? sourcePath.substring(sourcePath.lastIndexOf('.')).toLowerCase()
        : '.jpg';
    final safeExtension =
        ['.jpg', '.jpeg', '.png', '.webp', '.heic'].contains(extension)
        ? extension
        : '.jpg';
    final destination = File(
      '${directory.path}/${prefix}_${DateTime.now().microsecondsSinceEpoch}$safeExtension',
    );
    await source.copy(destination.path);
    return destination.path;
  }

  Future<String> persistRemoteImage(
    String sourceUrl, {
    required String prefix,
  }) async {
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null || uri.scheme != 'https') {
      throw const FormatException('Only HTTPS result images are accepted.');
    }
    final directory = await _appDirectory();
    final destination = File(
      '${directory.path}/${prefix}_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const HttpException('Result image download failed.');
      }
      final sink = destination.openWrite();
      await response.pipe(sink);
      return destination.path;
    } on Object {
      if (destination.existsSync()) await destination.delete();
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  Future<LocalSnapshot> load() async {
    final file = await _dataFile();
    if (!file.existsSync()) {
      return const LocalSnapshot(
        onboardingComplete: false,
        demoMode: false,
        garments: [],
        outfits: [],
      );
    }
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return LocalSnapshot(
        onboardingComplete: json['onboardingComplete'] as bool? ?? false,
        demoMode: json['demoMode'] as bool? ?? false,
        profile: json['profile'] == null
            ? null
            : UserProfile.fromJson(
                Map<String, Object?>.from(json['profile'] as Map),
              ),
        garments: (json['garments'] as List? ?? const [])
            .map(
              (item) =>
                  Garment.fromJson(Map<String, Object?>.from(item as Map)),
            )
            .toList(),
        outfits: (json['outfits'] as List? ?? const [])
            .map(
              (item) => Outfit.fromJson(Map<String, Object?>.from(item as Map)),
            )
            .toList(),
      );
    } on Object {
      final backup = File('${file.path}.corrupted');
      await file.rename(backup.path);
      return const LocalSnapshot(
        onboardingComplete: false,
        demoMode: false,
        garments: [],
        outfits: [],
      );
    }
  }

  Future<void> save({
    required bool onboardingComplete,
    required bool demoMode,
    required UserProfile? profile,
    required List<Garment> garments,
    required List<Outfit> outfits,
  }) async {
    final file = await _dataFile();
    final temporary = File('${file.path}.tmp');
    final payload = jsonEncode({
      'schemaVersion': 1,
      'onboardingComplete': onboardingComplete,
      'demoMode': demoMode,
      'profile': profile?.toJson(),
      'garments': garments
          .where((item) => !item.isDemo)
          .map((item) => item.toJson())
          .toList(),
      'outfits': outfits.map((item) => item.toJson()).toList(),
    });
    await temporary.writeAsString(payload, flush: true);
    if (file.existsSync()) {
      await file.delete();
    }
    await temporary.rename(file.path);
  }

  Future<void> deleteManagedFile(String path) async {
    if (path.startsWith('demo://') || path.startsWith('http')) return;
    final directory = await _appDirectory();
    if (!path.startsWith('${directory.path}/')) return;
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }

  Future<void> deleteAll() async {
    final directory = await _appDirectory();
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  }
}
