import 'package:simsrl/models/try_on_generation.dart';

class TryOnRequest {
  const TryOnRequest({required this.personImagePath, required this.garments});

  final String personImagePath;
  final List<TryOnGarmentInput> garments;
}

class TryOnGarmentInput {
  const TryOnGarmentInput({required this.imagePath, required this.category});

  final String imagePath;
  final String category;
}

abstract interface class VirtualTryOnProvider {
  String get name;
  bool get isMock;

  Future<TryOnGeneration> generateOutfit(TryOnRequest request);
  Future<TryOnGeneration> getStatus(String generationId);
}

class VirtualTryOnException implements Exception {
  const VirtualTryOnException(this.message);
  final String message;

  @override
  String toString() => message;
}
