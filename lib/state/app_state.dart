import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:simsrl/models/garment.dart';
import 'package:simsrl/models/outfit.dart';
import 'package:simsrl/models/try_on_generation.dart';
import 'package:simsrl/models/user_profile.dart';
import 'package:simsrl/services/backend_virtual_try_on_provider.dart';
import 'package:simsrl/services/local_storage_service.dart';
import 'package:simsrl/services/mock_virtual_try_on_provider.dart';
import 'package:simsrl/services/virtual_try_on_provider.dart';

class AppState extends ChangeNotifier {
  AppState({LocalStorageService? storage})
    : _storage = storage ?? LocalStorageService();

  static const vtonApiBaseUrl = String.fromEnvironment('VTON_API_BASE_URL');

  final LocalStorageService _storage;
  final Map<GarmentCategory, String> _selection = {};

  bool isLoading = true;
  bool onboardingComplete = false;
  bool demoMode = false;
  UserProfile? profile;
  List<Garment> garments = [];
  List<Outfit> outfits = [];
  String? lastError;

  VirtualTryOnProvider get tryOnProvider => vtonApiBaseUrl.trim().isEmpty
      ? MockVirtualTryOnProvider()
      : BackendVirtualTryOnProvider(
          baseUrl: vtonApiBaseUrl.trim().replaceAll(RegExp(r'/$'), ''),
        );

  bool get hasRealTryOnProvider => vtonApiBaseUrl.trim().isNotEmpty;

  List<Garment> garmentsFor(GarmentCategory category) =>
      garments.where((garment) => garment.category == category).toList();

  Garment? selectedFor(GarmentCategory category) {
    final id = _selection[category];
    if (id == null) return null;
    return garments.where((garment) => garment.id == id).firstOrNull;
  }

  List<Garment> get selectedGarments => GarmentCategory.values
      .map(selectedFor)
      .whereType<Garment>()
      .toList(growable: false);

  Future<void> initialize() async {
    try {
      final snapshot = await _storage.load();
      onboardingComplete = snapshot.onboardingComplete;
      demoMode = snapshot.demoMode;
      profile = snapshot.profile;
      garments = [...snapshot.garments];
      outfits = [...snapshot.outfits];
      if (demoMode) _appendDemoGarments();
      _ensureValidSelection();
    } on Object {
      lastError = 'Tes données n’ont pas pu être chargées.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding(String frontPhotoSourcePath) async {
    final storedPath = await _storage.persistImage(
      frontPhotoSourcePath,
      prefix: 'profile',
    );
    profile = UserProfile(
      id: 'local_user',
      frontPhotoPath: storedPath,
      createdAt: DateTime.now(),
    );
    onboardingComplete = true;
    await _save();
    notifyListeners();
  }

  Future<void> updateProfilePhoto(String sourcePath) async {
    final previous = profile?.frontPhotoPath;
    final storedPath = await _storage.persistImage(
      sourcePath,
      prefix: 'profile',
    );
    profile = UserProfile(
      id: profile?.id ?? 'local_user',
      frontPhotoPath: storedPath,
      displayName: profile?.displayName,
      createdAt: profile?.createdAt ?? DateTime.now(),
    );
    await _save();
    if (previous != null) await _storage.deleteManagedFile(previous);
    notifyListeners();
  }

  Future<Garment> addGarment({
    required String sourcePath,
    required GarmentCategory category,
    required String subcategory,
    String? color,
  }) async {
    final storedPath = await _storage.persistImage(
      sourcePath,
      prefix: 'garment',
    );
    final garment = Garment(
      id: 'garment_${DateTime.now().microsecondsSinceEpoch}',
      originalImagePath: storedPath,
      category: category,
      subcategory: subcategory,
      color: color?.trim().isEmpty ?? true ? null : color!.trim(),
      createdAt: DateTime.now(),
    );
    garments = [garment, ...garments];
    _selection.putIfAbsent(category, () => garment.id);
    await _save();
    notifyListeners();
    return garment;
  }

  Future<void> updateGarment(Garment updated) async {
    garments = [
      for (final garment in garments)
        if (garment.id == updated.id) updated else garment,
    ];
    _ensureValidSelection();
    await _save();
    notifyListeners();
  }

  Future<void> toggleGarmentFavorite(String id) async {
    final garment = garments.where((item) => item.id == id).firstOrNull;
    if (garment == null) return;
    await updateGarment(garment.copyWith(isFavorite: !garment.isFavorite));
  }

  Future<void> deleteGarment(String id) async {
    final garment = garments.where((item) => item.id == id).firstOrNull;
    if (garment == null) return;
    garments = garments.where((item) => item.id != id).toList();
    _selection.removeWhere((_, selectedId) => selectedId == id);
    _ensureValidSelection();
    await _save();
    await _storage.deleteManagedFile(garment.originalImagePath);
    if (garment.processedImagePath != null) {
      await _storage.deleteManagedFile(garment.processedImagePath!);
    }
    notifyListeners();
  }

  void selectGarment(GarmentCategory category, String garmentId) {
    if (!garments.any(
      (item) => item.id == garmentId && item.category == category,
    )) {
      return;
    }
    _selection[category] = garmentId;
    notifyListeners();
  }

  void cycleGarment(GarmentCategory category, int direction) {
    final options = garmentsFor(category);
    if (options.isEmpty) return;
    final currentId = _selection[category];
    final current = options.indexWhere((item) => item.id == currentId);
    final next = current < 0 ? 0 : (current + direction) % options.length;
    _selection[category] = options[next < 0 ? options.length - 1 : next].id;
    notifyListeners();
  }

  Future<TryOnGeneration> generateOutfit() async {
    final currentProfile = profile;
    if (currentProfile == null) {
      throw const VirtualTryOnException(
        'Ajoute d’abord une photo de ton modèle.',
      );
    }
    final selected = selectedGarments;
    if (!selected.any((item) => item.category == GarmentCategory.tops) ||
        !selected.any((item) => item.category == GarmentCategory.bottoms)) {
      throw const VirtualTryOnException(
        'Choisis au minimum un haut et un bas.',
      );
    }

    final provider = tryOnProvider;
    var generation = await provider.generateOutfit(
      TryOnRequest(
        personImagePath: currentProfile.frontPhotoPath,
        garments: selected
            .map(
              (item) => TryOnGarmentInput(
                imagePath: item.displayImagePath,
                category: item.category.name,
              ),
            )
            .toList(),
      ),
    );
    final deadline = DateTime.now().add(const Duration(minutes: 2));
    while (!generation.isTerminal && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 2));
      generation = await provider.getStatus(generation.id);
    }
    if (!generation.isTerminal) {
      throw const VirtualTryOnException(
        'La génération prend plus de temps que prévu. Réessaie dans un instant.',
      );
    }
    if (generation.status == TryOnStatus.failed ||
        generation.resultImagePath == null) {
      throw VirtualTryOnException(
        generation.errorMessage ?? 'La tenue n’a pas pu être générée.',
      );
    }
    return generation;
  }

  Future<Outfit> saveOutfit(TryOnGeneration generation) async {
    final existing = outfits
        .where((item) => item.id == generation.id)
        .firstOrNull;
    if (existing != null) return existing;
    final imagePath = generation.isRemoteResult
        ? await _storage.persistRemoteImage(
            generation.resultImagePath!,
            prefix: 'outfit',
          )
        : generation.resultImagePath!;
    final outfit = Outfit(
      id: generation.id,
      imagePath: imagePath,
      garmentIds: selectedGarments.map((item) => item.id).toList(),
      createdAt: DateTime.now(),
      isRemoteImage: false,
    );
    outfits = [outfit, ...outfits];
    await _save();
    notifyListeners();
    return outfit;
  }

  Future<void> toggleOutfitFavorite(String id) async {
    outfits = [
      for (final outfit in outfits)
        if (outfit.id == id)
          outfit.copyWith(isFavorite: !outfit.isFavorite)
        else
          outfit,
    ];
    await _save();
    notifyListeners();
  }

  Future<void> deleteOutfit(String id) async {
    final outfit = outfits.where((item) => item.id == id).firstOrNull;
    outfits = outfits.where((item) => item.id != id).toList();
    await _save();
    if (outfit != null && !outfit.isRemoteImage) {
      final usedByProfile = outfit.imagePath == profile?.frontPhotoPath;
      if (!usedByProfile) await _storage.deleteManagedFile(outfit.imagePath);
    }
    notifyListeners();
  }

  Future<void> setDemoMode(bool value) async {
    demoMode = value;
    garments = garments.where((item) => !item.isDemo).toList();
    if (value) _appendDemoGarments();
    _ensureValidSelection();
    await _save();
    notifyListeners();
  }

  Future<void> resetAllData() async {
    await _storage.deleteAll();
    onboardingComplete = false;
    demoMode = false;
    profile = null;
    garments = [];
    outfits = [];
    _selection.clear();
    notifyListeners();
  }

  Future<void> _save() => _storage.save(
    onboardingComplete: onboardingComplete,
    demoMode: demoMode,
    profile: profile,
    garments: garments,
    outfits: outfits,
  );

  void _ensureValidSelection() {
    for (final category in GarmentCategory.values) {
      final options = garmentsFor(category);
      if (options.isEmpty) {
        _selection.remove(category);
      } else if (!options.any((item) => item.id == _selection[category])) {
        _selection[category] = options.first.id;
      }
    }
  }

  void _appendDemoGarments() {
    final now = DateTime.now();
    const demos = [
      (GarmentCategory.tops, 'T-shirt blanc', '#F2F0EA'),
      (GarmentCategory.tops, 'Hoodie noir', '#252525'),
      (GarmentCategory.tops, 'Chemise bleue', '#708EAD'),
      (GarmentCategory.bottoms, 'Jean brut', '#304C6D'),
      (GarmentCategory.bottoms, 'Pantalon beige', '#C5B69A'),
      (GarmentCategory.outerwear, 'Blazer noir', '#303033'),
      (GarmentCategory.shoes, 'Sneakers blanches', '#EAE9E4'),
      (GarmentCategory.shoes, 'Bottes noires', '#2A2927'),
    ];
    garments.addAll([
      for (var index = 0; index < demos.length; index++)
        Garment(
          id: 'demo_$index',
          originalImagePath: 'demo://${demos[index].$3}',
          category: demos[index].$1,
          subcategory: demos[index].$2,
          color: demos[index].$3,
          createdAt: now,
          isDemo: true,
        ),
    ]);
  }
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
