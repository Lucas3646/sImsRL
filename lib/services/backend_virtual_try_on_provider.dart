import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:simsrl/models/try_on_generation.dart';
import 'package:simsrl/services/virtual_try_on_provider.dart';

class BackendVirtualTryOnProvider implements VirtualTryOnProvider {
  BackendVirtualTryOnProvider({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  String get name => 'Virtual Try-On IA';

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
    if (request.garments.isEmpty) {
      throw const VirtualTryOnException('Choisis au moins un vêtement.');
    }
    if (request.garments.any(
      (garment) => garment.imagePath.startsWith('demo://'),
    )) {
      throw const VirtualTryOnException(
        'Ajoute tes propres vêtements pour lancer une génération IA.',
      );
    }

    final uri = Uri.parse('$baseUrl/v1/try-on/generations');
    final multipart = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('person', person.path))
      ..fields['categories'] = jsonEncode(
        request.garments.map((garment) => garment.category).toList(),
      );
    for (final garment in request.garments) {
      final path = garment.imagePath;
      final file = File(path);
      if (!file.existsSync()) {
        throw const VirtualTryOnException(
          'Une photo de vêtement est introuvable.',
        );
      }
      multipart.files.add(
        await http.MultipartFile.fromPath('garments', file.path),
      );
    }

    try {
      final streamed = await _client
          .send(multipart)
          .timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw VirtualTryOnException(_friendlyError(response.statusCode));
      }
      return _fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } on VirtualTryOnException {
      rethrow;
    } on Object {
      throw const VirtualTryOnException(
        'La génération ne répond pas. Vérifie ta connexion et réessaie.',
      );
    }
  }

  @override
  Future<TryOnGeneration> getStatus(String generationId) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/v1/try-on/generations/$generationId'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw VirtualTryOnException(_friendlyError(response.statusCode));
      }
      return _fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } on VirtualTryOnException {
      rethrow;
    } on Object {
      throw const VirtualTryOnException(
        'Impossible de récupérer le résultat pour le moment.',
      );
    }
  }

  TryOnGeneration _fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String? ?? 'failed';
    final status = switch (rawStatus) {
      'queued' => TryOnStatus.queued,
      'processing' => TryOnStatus.processing,
      'succeeded' => TryOnStatus.succeeded,
      _ => TryOnStatus.failed,
    };
    return TryOnGeneration(
      id: json['id'] as String? ?? 'unknown',
      status: status,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      resultImagePath: json['resultUrl'] as String?,
      errorMessage: json['message'] as String?,
      isRemoteResult: true,
    );
  }

  String _friendlyError(int statusCode) => switch (statusCode) {
    401 || 403 => 'Le service IA n’est pas correctement configuré.',
    413 => 'Une des photos est trop lourde.',
    429 => 'Le service est très demandé. Réessaie dans un instant.',
    >= 500 => 'Le service IA rencontre un problème temporaire.',
    _ => 'La génération n’a pas pu démarrer.',
  };
}
