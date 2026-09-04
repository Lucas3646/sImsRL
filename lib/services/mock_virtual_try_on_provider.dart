import 'package:simsrl/models/try_on_generation.dart';
import 'package:simsrl/services/virtual_try_on_provider.dart';

class MockVirtualTryOnProvider implements VirtualTryOnProvider {
  final Map<String, TryOnGeneration> _results = {};

  @override
  String get name => 'Démo locale';

  @override
  bool get isMock => true;

  @override
  Future<TryOnGeneration> generateOutfit(TryOnRequest request) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    final id = 'mock_${DateTime.now().microsecondsSinceEpoch}';
    final result = TryOnGeneration(
      id: id,
      status: TryOnStatus.succeeded,
      createdAt: DateTime.now(),
      resultImagePath: request.personImagePath,
    );
    _results[id] = result;
    return result;
  }

  @override
  Future<TryOnGeneration> getStatus(String generationId) async {
    return _results[generationId] ??
        TryOnGeneration(
          id: generationId,
          status: TryOnStatus.failed,
          createdAt: DateTime.now(),
          errorMessage: 'Cette génération de démonstration a expiré.',
        );
  }
}
