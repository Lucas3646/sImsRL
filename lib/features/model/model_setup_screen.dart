import 'dart:io';

import 'package:flutter/material.dart';

import 'package:simsrl/core/theme/app_theme.dart';
import 'package:simsrl/services/media_service.dart';
import 'package:simsrl/state/app_scope.dart';

class ModelSetupScreen extends StatefulWidget {
  const ModelSetupScreen({this.editing = false, super.key});
  final bool editing;

  @override
  State<ModelSetupScreen> createState() => _ModelSetupScreenState();
}

class _ModelSetupScreenState extends State<ModelSetupScreen> {
  final _media = MediaService();
  String? _imagePath;
  bool _saving = false;
  String? _error;

  Future<void> _pick(bool camera) async {
    try {
      final path = camera
          ? await _media.pickFromCamera()
          : await _media.pickFromGallery();
      if (!mounted || path == null) return;
      setState(() {
        _imagePath = path;
        _error = null;
      });
    } on Object {
      if (mounted) setState(() => _error = 'Impossible d’ouvrir cette image.');
    }
  }

  Future<void> _chooseSource() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pick(true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choisir dans la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pick(false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _validate() async {
    final path = _imagePath;
    if (path == null) {
      setState(() => _error = 'Ajoute une photo en pied pour continuer.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final state = AppScope.of(context);
      if (widget.editing) {
        await state.updateProfilePhoto(path);
      } else {
        await state.completeOnboarding(path);
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } on Object {
      if (mounted)
        setState(() => _error = 'La photo n’a pas pu être enregistrée.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.editing ? 'Modifier mon modèle' : 'Crée ton modèle'),
    ),
    body: SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Une photo simple donne déjà de meilleurs résultats.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Tip(label: 'Corps entier visible'),
                    _Tip(label: 'Bonne lumière'),
                    _Tip(label: 'Fond simple'),
                    _Tip(label: 'Bras légèrement écartés'),
                    _Tip(label: 'Vêtements ajustés'),
                  ],
                ),
                const SizedBox(height: 20),
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: _saving ? null : _chooseSource,
                    child: Ink(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: _imagePath == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 46),
                                SizedBox(height: 12),
                                Text(
                                  'Ajouter ma photo',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Caméra ou galerie',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(27),
                              child: Image.file(
                                File(_imagePath!),
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                ),
                if (_imagePath != null) ...[
                  TextButton.icon(
                    onPressed: _saving ? null : _chooseSource,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Recommencer'),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _validate,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.editing ? 'Enregistrer' : 'Valider mon modèle',
                        ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'La photo reste privée sur ton téléphone en mode local.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Tip extends StatelessWidget {
  const _Tip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: AppColors.line),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}
