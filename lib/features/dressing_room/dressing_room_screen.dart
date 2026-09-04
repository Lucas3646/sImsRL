import 'package:flutter/material.dart';

import 'package:simsrl/core/theme/app_theme.dart';
import 'package:simsrl/core/widgets/adaptive_image.dart';
import 'package:simsrl/core/widgets/empty_state.dart';
import 'package:simsrl/features/dressing_room/generation_screen.dart';
import 'package:simsrl/features/model/model_setup_screen.dart';
import 'package:simsrl/features/wardrobe/garment_form_screen.dart';
import 'package:simsrl/models/garment.dart';
import 'package:simsrl/state/app_scope.dart';

class DressingRoomScreen extends StatelessWidget {
  const DressingRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final profile = state.profile;
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dressing Room'),
            Text(
              'Compose ton look',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: state.hasRealTryOnProvider
                  ? AppColors.lime
                  : AppColors.lavender.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              state.hasRealTryOnProvider ? 'IA PRÊTE' : 'MODE DÉMO',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      body: profile == null
          ? EmptyState(
              icon: Icons.accessibility_new_rounded,
              title: 'Crée ton modèle',
              message: 'Ajoute une photo en pied avant de composer une tenue.',
              action: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ModelSetupScreen(editing: true),
                  ),
                ),
                child: const Text('Ajouter ma photo'),
              ),
            )
          : SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    SizedBox(
                      height: (constraints.maxHeight * .42).clamp(250.0, 390.0),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: AdaptiveImage(
                              path: profile.frontPhotoPath,
                              borderRadius: BorderRadius.circular(30),
                              semanticLabel: 'Photo du modèle utilisateur',
                            ),
                          ),
                          Positioned(
                            left: 12,
                            bottom: 12,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.ink.withValues(alpha: .82),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.swipe,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Change les pièces dessous',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    for (final category in [
                      GarmentCategory.tops,
                      GarmentCategory.bottoms,
                      GarmentCategory.outerwear,
                      GarmentCategory.shoes,
                    ]) ...[
                      _GarmentSelector(category: category),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => _startGeneration(context),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Générer la tenue'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _startGeneration(BuildContext context) async {
    final state = AppScope.of(context);
    final hasTop = state.selectedFor(GarmentCategory.tops) != null;
    final hasBottom = state.selectedFor(GarmentCategory.bottoms) != null;
    if (!hasTop || !hasBottom) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoute et sélectionne au minimum un haut et un bas.'),
        ),
      );
      return;
    }
    if (state.hasRealTryOnProvider) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Envoi au service IA'),
          content: const Text(
            'Ta photo et les vêtements sélectionnés seront temporairement envoyés au fournisseur configuré pour générer le rendu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuer'),
            ),
          ],
        ),
      );
      if (!(accepted ?? false) || !context.mounted) return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const GenerationScreen()));
  }
}

class _GarmentSelector extends StatelessWidget {
  const _GarmentSelector({required this.category});
  final GarmentCategory category;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final selected = state.selectedFor(category);
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(
                category.label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Précédent',
            onPressed: selected == null
                ? null
                : () => state.cycleGarment(category, -1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: selected == null
                ? InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const GarmentFormScreen(),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '+ Ajouter',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: 52,
                        height: 58,
                        child: AdaptiveImage(
                          path: selected.displayImagePath,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selected.subcategory,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
          ),
          IconButton(
            tooltip: 'Suivant',
            onPressed: selected == null
                ? null
                : () => state.cycleGarment(category, 1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
