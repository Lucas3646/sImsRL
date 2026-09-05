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
                        ? state.hasHuggingFaceToken
                              ? 'Compte authentifié : quota gratuit quotidien et priorité améliorée.'
                              : 'Ajoute une clé gratuite pour activer les générations quotidiennes.'
                        : 'Les générations passent par ton backend privé.',
                  ),
                ),
                if (state.usesFreeTryOnProvider) ...[
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      state.hasHuggingFaceToken
                          ? Icons.verified_user_outlined
                          : Icons.key_outlined,
                    ),
                    title: Text(
                      state.hasHuggingFaceToken
                          ? 'Clé Hugging Face enregistrée'
                          : 'Connecter Hugging Face',
                    ),
                    subtitle: const Text(
                      'La clé reste chiffrée dans le stockage sécurisé du téléphone.',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _configureHuggingFace(context),
                  ),
                ],
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

  Future<void> _configureHuggingFace(BuildContext context) async {
    final state = AppScope.of(context);
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var hideToken = true;
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: const Icon(Icons.key_rounded),
          title: Text(
            state.hasHuggingFaceToken
                ? 'Compte Hugging Face connecté'
                : 'Connecter Hugging Face',
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Colle ta clé Read commençant par hf_. Elle ne sera jamais affichée après son enregistrement.',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: controller,
                  obscureText: hideToken,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    labelText: 'Clé Hugging Face',
                    hintText: 'hf_…',
                    suffixIcon: IconButton(
                      tooltip: hideToken ? 'Afficher' : 'Masquer',
                      onPressed: () => setDialogState(
                        () => hideToken = !hideToken,
                      ),
                      icon: Icon(
                        hideToken
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final token = value?.trim() ?? '';
                    if (!token.startsWith('hf_') || token.length < 12) {
                      return 'Clé invalide : elle doit commencer par hf_.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            if (state.hasHuggingFaceToken)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, 'remove'),
                child: const Text('Retirer la clé'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(dialogContext, controller.text.trim());
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (action == null || !context.mounted) return;
    if (action == 'remove') {
      await state.removeHuggingFaceToken();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clé Hugging Face supprimée.')),
      );
      return;
    }
    await state.saveHuggingFaceToken(action);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hugging Face est maintenant connecté.')),
    );
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
