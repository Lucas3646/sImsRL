import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:simsrl/core/theme/app_theme.dart';
import 'package:simsrl/core/widgets/adaptive_image.dart';
import 'package:simsrl/models/try_on_generation.dart';
import 'package:simsrl/services/virtual_try_on_provider.dart';
import 'package:simsrl/state/app_scope.dart';

class GenerationScreen extends StatefulWidget {
  const GenerationScreen({super.key});

  @override
  State<GenerationScreen> createState() => _GenerationScreenState();
}

class _GenerationScreenState extends State<GenerationScreen> {
  TryOnGeneration? _generation;
  String? _error;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  Future<void> _generate() async {
    setState(() {
      _generation = null;
      _error = null;
      _saved = false;
    });
    try {
      final result = await AppScope.of(context).generateOutfit();
      if (mounted) {
        setState(() => _generation = result);
      }
    } on VirtualTryOnException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Object {
      if (mounted)
        setState(() => _error = 'Un problème inattendu est survenu. Réessaie.');
    }
  }

  Future<void> _save() async {
    final generation = _generation;
    if (generation == null) {
      return;
    }
    await AppScope.of(context).saveOutfit(generation);
    if (mounted) {
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tenue sauvegardée dans Mes tenues.')),
      );
    }
  }

  Future<void> _share() async {
    final path = _generation?.resultImagePath;
    if (path == null) return;
    if (path.startsWith('http')) {
      await SharePlus.instance.share(
        ShareParams(text: 'Mon outfit sImsRL : $path'),
      );
    } else {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: 'Mon outfit sImsRL'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ton outfit')),
      body: SafeArea(
        top: false,
        child: _error != null
            ? _ErrorState(message: _error!, onRetry: _generate)
            : _generation == null
            ? _LoadingState(isMock: !state.hasRealTryOnProvider)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AdaptiveImage(
                          path: _generation!.resultImagePath!,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        if (!state.hasRealTryOnProvider)
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.ink.withValues(alpha: .88),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'Aperçu démo : configure VTON_API_BASE_URL pour obtenir un vrai rendu IA.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _saved ? null : _save,
                    icon: Icon(
                      _saved
                          ? Icons.check_rounded
                          : Icons.favorite_border_rounded,
                    ),
                    label: Text(_saved ? 'Tenue sauvegardée' : 'Sauvegarder'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _generate,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Régénérer'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _share,
                          icon: const Icon(Icons.ios_share_rounded),
                          label: const Text('Partager'),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Modifier la tenue'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.isMock});
  final bool isMock;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 3),
            tween: Tween(begin: .05, end: .92),
            builder: (context, value, _) => SizedBox(
              width: 88,
              height: 88,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 8,
                backgroundColor: AppColors.line,
              ),
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'Création de ton outfit…',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            isMock
                ? 'Simulation locale en cours.'
                : 'On assemble les pièces tout en préservant ton identité.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 62),
          const SizedBox(height: 18),
          Text(
            'La génération a échoué',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    ),
  );
}
