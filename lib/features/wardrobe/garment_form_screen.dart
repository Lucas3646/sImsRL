import 'dart:io';

import 'package:flutter/material.dart';

import 'package:simsrl/core/theme/app_theme.dart';
import 'package:simsrl/core/widgets/adaptive_image.dart';
import 'package:simsrl/models/garment.dart';
import 'package:simsrl/services/media_service.dart';
import 'package:simsrl/state/app_scope.dart';

class GarmentFormScreen extends StatefulWidget {
  const GarmentFormScreen({this.garment, super.key});
  final Garment? garment;

  @override
  State<GarmentFormScreen> createState() => _GarmentFormScreenState();
}

class _GarmentFormScreenState extends State<GarmentFormScreen> {
  final _media = MediaService();
  final _colorController = TextEditingController();
  String? _sourcePath;
  late GarmentCategory _category;
  late String _subcategory;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.garment != null;

  @override
  void initState() {
    super.initState();
    final garment = widget.garment;
    _category = garment?.category ?? GarmentCategory.tops;
    _subcategory = garment?.subcategory ?? _category.subcategories.first;
    _colorController.text = garment?.color ?? '';
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _pick(bool camera) async {
    final path = camera
        ? await _media.pickFromCamera()
        : await _media.pickFromGallery();
    if (!mounted || path == null) return;
    setState(() {
      _sourcePath = path;
      _error = null;
    });
  }

  Future<void> _chooseSource() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
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
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_editing && _sourcePath == null) {
      setState(() => _error = 'Ajoute une photo du vêtement.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final state = AppScope.of(context);
      if (_editing) {
        await state.updateGarment(
          widget.garment!.copyWith(
            category: _category,
            subcategory: _subcategory,
            color: _colorController.text,
          ),
        );
      } else {
        await state.addGarment(
          sourcePath: _sourcePath!,
          category: _category,
          subcategory: _subcategory,
          color: _colorController.text,
        );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } on Object {
      if (mounted)
        setState(() => _error = 'Ce vêtement n’a pas pu être enregistré.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _sourcePath ?? widget.garment?.displayImagePath;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Modifier le vêtement' : 'Nouveau vêtement'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: InkWell(
                onTap: _editing ? null : _chooseSource,
                borderRadius: BorderRadius.circular(26),
                child: Ink(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: imagePath == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 46),
                            SizedBox(height: 10),
                            Text(
                              'Photographier le vêtement',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'À plat, avec une lumière uniforme',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: _sourcePath == null
                              ? AdaptiveImage(path: imagePath)
                              : Image.file(File(imagePath), fit: BoxFit.cover),
                        ),
                ),
              ),
            ),
            if (!_editing && imagePath != null)
              TextButton.icon(
                onPressed: _chooseSource,
                icon: const Icon(Icons.crop_rounded),
                label: const Text('Changer la photo'),
              ),
            const SizedBox(height: 18),
            DropdownButtonFormField<GarmentCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: GarmentCategory.values
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _category = value;
                  _subcategory = value.subcategories.first;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _subcategory,
              decoration: const InputDecoration(labelText: 'Type'),
              items: _category.subcategories
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _subcategory = value ?? _subcategory),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _colorController,
              decoration: const InputDecoration(
                labelText: 'Couleur (optionnel)',
                hintText: 'Ex. bleu marine',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lime.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_fix_high_outlined, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Le détourage automatique arrivera via un service interchangeable. La photo originale reste utilisable si le traitement échoue.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _editing
                          ? 'Enregistrer les modifications'
                          : 'Ajouter au dressing',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
