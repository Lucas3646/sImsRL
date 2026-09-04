import 'package:flutter/material.dart';

import 'package:simsrl/core/theme/app_theme.dart';
import 'package:simsrl/core/widgets/adaptive_image.dart';
import 'package:simsrl/features/model/model_setup_screen.dart';
import 'package:simsrl/state/app_scope.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final profile = state.profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (profile != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 82,
                        height: 108,
                        child: AdaptiveImage(
                          path: profile.frontPhotoPath,
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mon modèle',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Photo de face',
                              style: TextStyle(color: AppColors.muted),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const ModelSetupScreen(editing: true),
                                ),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Modifier'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _Section(
              title: 'Mode de test',
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vêtements de démonstration'),
                  subtitle: const Text(
                    'Ajoute des pièces fictives, séparées de tes vraies données.',
                  ),
                  value: state.demoMode,
                  onChanged: state.setDemoMode,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Virtual Try-On',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: state.hasRealTryOnProvider
                        ? AppColors.lime
                        : AppColors.lavender,
                    child: Icon(
                      state.hasRealTryOnProvider
                          ? Icons.cloud_done
                          : Icons.science_outlined,
                    ),
                  ),
                  title: Text(
                    state.usesFreeTryOnProvider
                        ? 'CatVTON gratuit actif'
                        : 'Provider IA privé configuré',
                  ),
                  subtitle: Text(
                    state.usesFreeTryOnProvider
                        ? 'Rendu réel via ZeroGPU : file d’attente et quota quotidien possibles.'
                        : 'Les générations passent par ton backend privé.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _Section(
              title: 'Confidentialité',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.lock_outline_rounded),
                  title: Text('Stockage privé local'),
                  subtitle: Text(
                    'Tes photos restent dans le dossier privé de l’application. Un accord est demandé avant tout envoi au service IA.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
              ),
              onPressed: () => _confirmReset(context),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Supprimer toutes mes données'),
            ),
            const SizedBox(height: 18),
            const Text(
              'sImsRL • V1 locale',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final state = AppScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tout supprimer ?'),
        content: const Text(
          'Ton modèle, tes vêtements et tes tenues seront définitivement supprimés de ce téléphone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tout supprimer'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await state.resetAllData();
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}
