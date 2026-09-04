import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'package:simsrl/models/try_on_generation.dart';
import 'package:simsrl/services/virtual_try_on_provider.dart';

/// Calls the public CatVTON Gradio Space hosted on Hugging Face ZeroGPU.
///
/// This provider is intended for non-commercial product testing. The public
/// Space can queue requests, sleep, or reject them when its free daily quota is
/// exhausted.
class HuggingFaceCatVtonProvider implements VirtualTryOnProvider {
  HuggingFaceCatVtonProvider({
    http.Client? client,
    this.baseUrl = 'https://zhengchong-catvton.hf.space',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  @override
  String get name => 'CatVTON ZeroGPU gratuit';

  @override
  bool get isMock => false;

  @override
  Future<TryOnGeneration> generateOutfit(TryOnRequest request) async {
    final person = File(request.personImagePath);
    if (!person.existsSync()) {
      throw const VirtualTryOnException(
        'La photo de ton modèle est introuvable.',
      );
    }
    if (request.garments.any(
      (garment) => garment.imagePath.startsWith('demo://'),
    )) {
      throw const VirtualTryOnException(
        'Le rendu IA gratuit fonctionne uniquement avec tes propres photos.',
      );
    }

    final supported = request.garments
        .where(
          (garment) =>
              garment.category == 'tops' || garment.category == 'bottoms',
        )
        .toList()
      ..sort((a, b) => _order(a.category).compareTo(_order(b.category)));
    if (supported.length < 2) {
      throw const VirtualTryOnException(
        'CatVTON a besoin de la photo d’un haut et d’un bas.',
      );
    }

    try {
      Map<String, dynamic> currentPerson = await _upload(person.path);
      String? resultUrl;
      for (final garment in supported.take(2)) {
        final garmentFile = File(garment.imagePath);
        if (!garmentFile.existsSync()) {
          throw const VirtualTryOnException(
            'Une photo de vêtement est introuvable.',
          );
        }
        final cloth = await _upload(garmentFile.path);
        resultUrl = await _submit(
          person: currentPerson,
          cloth: cloth,
          clothType: garment.category == 'bottoms' ? 'lower' : 'upper',
        );
        currentPerson = _remoteFileData(resultUrl);
      }

      if (resultUrl == null) {
        throw const VirtualTryOnException(
          'CatVTON n’a retourné aucune image.',
        );
      }
      return TryOnGeneration(
        id: 'catvton_${DateTime.now().microsecondsSinceEpoch}',
        status: TryOnStatus.succeeded,
        createdAt: DateTime.now(),
        resultImagePath: resultUrl,
        isRemoteResult: true,
      );
    } on VirtualTryOnException {
      rethrow;
    } on TimeoutException {
      throw const VirtualTryOnException(
        'La file d’attente gratuite est trop longue. Réessaie plus tard.',
      );
    } on Object {
      throw const VirtualTryOnException(
        'CatVTON gratuit ne répond pas pour le moment. Réessaie dans quelques minutes.',
      );
    }
  }

  @override
  Future<TryOnGeneration> getStatus(String generationId) async =>
      TryOnGeneration(
        id: generationId,
        status: TryOnStatus.failed,
        createdAt: DateTime.now(),
        errorMessage: 'Cette génération gratuite n’existe plus.',
      );

  Future<Map<String, dynamic>> _upload(String path) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/gradio_api/upload'),
    )..files.add(await http.MultipartFile.fromPath('files', path));
    final streamed = await _client
        .send(request)
        .timeout(const Duration(seconds: 45));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForStatus(response.statusCode);
    }

    final decoded = jsonDecode(response.body);
    final Object? first = decoded is List && decoded.isNotEmpty
        ? decoded.first
        : decoded;
    final uploadedPath = switch (first) {
      String value => value,
      Map value => value['path'] as String?,
      _ => null,
    };
    if (uploadedPath == null || uploadedPath.isEmpty) {
      throw const VirtualTryOnException(
        'Hugging Face n’a pas accepté une des photos.',
      );
    }
    final file = File(path);
    return {
      'path': uploadedPath,
      'url': null,
      'size': file.lengthSync(),
      'orig_name': _basename(path),
      'mime_type': _mimeType(path),
      'is_stream': false,
      'meta': const {'_type': 'gradio.FileData'},
    };
  }

  Future<String> _submit({
    required Map<String, dynamic> person,
    required Map<String, dynamic> cloth,
    required String clothType,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/gradio_api/call/submit_function'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'data': [
              {'background': person, 'layers': const [], 'composite': null},
              cloth,
              clothType,
              30,
              2.5,
              Random.secure().nextInt(10000),
              'result only',
            ],
          }),
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForStatus(response.statusCode);
    }
    final eventId =
        (jsonDecode(response.body) as Map<String, dynamic>)['event_id']
            as String?;
    if (eventId == null || eventId.isEmpty) {
      throw const VirtualTryOnException(
        'CatVTON n’a pas pu placer la génération dans la file.',
      );
    }
    return _waitForResult(eventId);
  }

  Future<String> _waitForResult(String eventId) async {
    final request = http.Request(
      'GET',
      Uri.parse('$baseUrl/gradio_api/call/submit_function/$eventId'),
    )..headers['accept'] = 'text/event-stream';
    final streamed = await _client
        .send(request)
        .timeout(const Duration(seconds: 45));
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      _throwForStatus(streamed.statusCode);
    }
    final body = await streamed.stream
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(minutes: 3));

    String? currentEvent;
    for (final line in const LineSplitter().convert(body)) {
      if (line.startsWith('event:')) {
        currentEvent = line.substring(6).trim();
        continue;
      }
      if (!line.startsWith('data:')) continue;
      final data = line.substring(5).trim();
      if (currentEvent == 'error') {
        throw const VirtualTryOnException(
          'Le quota gratuit ou la file CatVTON est indisponible. Réessaie plus tard.',
        );
      }
      if (currentEvent != 'complete') continue;
      final decoded = jsonDecode(data);
      final Object? first = decoded is List && decoded.isNotEmpty
          ? decoded.first
          : decoded;
      if (first is Map) {
        final rawUrl = first['url'] as String? ?? first['path'] as String?;
        if (rawUrl != null && rawUrl.isNotEmpty) {
          return Uri.parse(baseUrl).resolve(rawUrl).toString();
        }
      }
    }
    throw const VirtualTryOnException(
      'CatVTON n’a pas retourné de résultat exploitable.',
    );
  }

  Never _throwForStatus(int statusCode) {
    if (statusCode == 401 || statusCode == 403 || statusCode == 429) {
      throw const VirtualTryOnException(
        'Le quota IA gratuit est atteint. Réessaie après sa réinitialisation.',
      );
    }
    if (statusCode >= 500) {
      throw const VirtualTryOnException(
        'Le Space CatVTON est temporairement indisponible.',
      );
    }
    throw const VirtualTryOnException(
      'Une photo n’a pas été acceptée par CatVTON.',
    );
  }

  Map<String, dynamic> _remoteFileData(String url) => {
    'path': null,
    'url': url,
    'size': null,
    'orig_name': 'catvton-result.png',
    'mime_type': 'image/png',
    'is_stream': false,
    'meta': const {'_type': 'gradio.FileData'},
  };

  int _order(String category) => category == 'tops' ? 0 : 1;

  String _basename(String path) =>
      path.substring(path.replaceAll('\\', '/').lastIndexOf('/') + 1);

  String _mimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
