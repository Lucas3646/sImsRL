import 'package:flutter/material.dart';

import 'package:simsrl/core/theme/app_theme.dart';
import 'package:simsrl/core/widgets/adaptive_image.dart';
import 'package:simsrl/core/widgets/empty_state.dart';
import 'package:simsrl/features/wardrobe/garment_form_screen.dart';
import 'package:simsrl/models/garment.dart';
import 'package:simsrl/state/app_scope.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  GarmentCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final visible = _filter == null
        ? state.garments
        : state.garments.where((item) => item.category == _filter).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon dressing'),
        actions: [
          IconButton(
            tooltip: 'Ajouter un vêtement',
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add_circle_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(
              height: 50,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'Tous',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (final category in [
                    GarmentCategory.tops,
                    GarmentCategory.bottoms,
                    GarmentCategory.outerwear,
                    GarmentCategory.shoes,
                  ])
                    _FilterChip(
                      label: category.label,
                      selected: _filter == category,
                      onTap: () => setState(() => _filter = category),
                    ),
                ],
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? EmptyState(
                      icon: Icons.checkroom_rounded,
                      title: state.garments.isEmpty
                          ? 'Ton dressing est vide'
                          : 'Aucun vêtement ici',
                      message: state.garments.isEmpty
                          ? 'Commence par ajouter un T-shirt et un pantalon.'
                          : 'Essaie un autre filtre ou ajoute un vêtement.',
                      action: FilledButton.icon(
                        onPressed: () => _openForm(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Ajouter un vêtement'),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: .76,
                          ),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final garment = visible[index];
                        return _GarmentCard(
                          garment: garment,
                          onTap: () => _showActions(context, garment),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: visible.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Vêtement'),
            ),
    );
  }

  Future<void> _openForm(BuildContext context, [Garment? garment]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GarmentFormScreen(garment: garment),
      ),
    );
  }

  Future<void> _showActions(BuildContext context, Garment garment) async {
    final state = AppScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  garment.subcategory,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(garment.category.label),
                trailing: IconButton(
                  tooltip: garment.isFavorite
                      ? 'Retirer des favoris'
                      : 'Ajouter aux favoris',
                  onPressed: () async {
                    await state.toggleGarmentFavorite(garment.id);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  icon: Icon(
                    garment.isFavorite ? Icons.favorite : Icons.favorite_border,
                  ),
                ),
              ),
              if (!garment.isDemo)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Modifier'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openForm(context, garment);
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Supprimer ce vêtement ?'),
                      content: const Text(
                        'Il disparaîtra aussi des sélections en cours.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Supprimer'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed ?? false) await state.deleteGarment(garment.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );
}

class _GarmentCard extends StatelessWidget {
  const _GarmentCard({required this.garment, required this.onTap});
  final Garment garment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                AdaptiveImage(path: garment.displayImagePath),
                if (garment.isFavorite)
                  const Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.favorite,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                    ),
                  ),
                if (garment.isDemo)
                  const Positioned(
                    top: 10,
                    left: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.all(Radius.circular(99)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          'DÉMO',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  garment.subcategory,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  garment.category.label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
