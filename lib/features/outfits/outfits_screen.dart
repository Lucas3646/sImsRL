import 'package:flutter/material.dart';

import 'package:simsrl/core/theme/app_theme.dart';
import 'package:simsrl/core/widgets/adaptive_image.dart';
import 'package:simsrl/core/widgets/empty_state.dart';
import 'package:simsrl/models/outfit.dart';
import 'package:simsrl/state/app_scope.dart';

class OutfitsScreen extends StatelessWidget {
  const OutfitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final outfits = [...state.outfits]
      ..sort((a, b) {
        if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    return Scaffold(
      appBar: AppBar(title: const Text('Mes tenues')),
      body: SafeArea(
        top: false,
        child: outfits.isEmpty
            ? const EmptyState(
                icon: Icons.collections_bookmark_rounded,
                title: 'Aucune tenue sauvegardée',
                message: 'Compose ton premier look dans le Dressing Room.',
              )
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: .68,
                ),
                itemCount: outfits.length,
                itemBuilder: (context, index) {
                  final outfit = outfits[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _openOutfit(context, outfit),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AdaptiveImage(path: outfit.imagePath),
                          Positioned(
                            left: 10,
                            right: 10,
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.ink.withValues(alpha: .78),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _dateLabel(outfit.createdAt),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    outfit.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: outfit.isFavorite
                                        ? AppColors.coral
                                        : Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _openOutfit(BuildContext context, Outfit outfit) async {
    final state = AppScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * .62,
                ),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: AdaptiveImage(
                    path: outfit.imagePath,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await state.toggleOutfitFavorite(outfit.id);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                      icon: Icon(
                        outfit.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                      ),
                      label: Text(
                        outfit.isFavorite ? 'Favori' : 'Ajouter aux favoris',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    tooltip: 'Supprimer',
                    onPressed: () async {
                      await state.deleteOutfit(outfit.id);
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
