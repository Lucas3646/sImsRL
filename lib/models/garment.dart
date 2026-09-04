enum GarmentCategory { tops, bottoms, outerwear, shoes, accessories, other }

extension GarmentCategoryX on GarmentCategory {
  String get label => switch (this) {
    GarmentCategory.tops => 'Hauts',
    GarmentCategory.bottoms => 'Bas',
    GarmentCategory.outerwear => 'Vestes',
    GarmentCategory.shoes => 'Chaussures',
    GarmentCategory.accessories => 'Accessoires',
    GarmentCategory.other => 'Autres',
  };

  List<String> get subcategories => switch (this) {
    GarmentCategory.tops => [
      'T-shirt',
      'Chemise',
      'Polo',
      'Pull',
      'Sweat / hoodie',
      'Autre haut',
    ],
    GarmentCategory.bottoms => [
      'Jean',
      'Pantalon',
      'Short',
      'Jogging',
      'Autre bas',
    ],
    GarmentCategory.outerwear => ['Veste', 'Manteau', 'Blazer'],
    GarmentCategory.shoes => [
      'Sneakers',
      'Chaussures',
      'Bottes',
      'Autres chaussures',
    ],
    GarmentCategory.accessories => ['Accessoire'],
    GarmentCategory.other => ['Autre'],
  };
}

class Garment {
  const Garment({
    required this.id,
    required this.originalImagePath,
    required this.category,
    required this.subcategory,
    required this.createdAt,
    this.processedImagePath,
    this.color,
    this.isFavorite = false,
    this.isDemo = false,
  });

  final String id;
  final String originalImagePath;
  final String? processedImagePath;
  final GarmentCategory category;
  final String subcategory;
  final String? color;
  final DateTime createdAt;
  final bool isFavorite;
  final bool isDemo;

  String get displayImagePath => processedImagePath ?? originalImagePath;

  Garment copyWith({
    String? processedImagePath,
    GarmentCategory? category,
    String? subcategory,
    String? color,
    bool? isFavorite,
  }) {
    return Garment(
      id: id,
      originalImagePath: originalImagePath,
      processedImagePath: processedImagePath ?? this.processedImagePath,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      color: color ?? this.color,
      createdAt: createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isDemo: isDemo,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'originalImagePath': originalImagePath,
    'processedImagePath': processedImagePath,
    'category': category.name,
    'subcategory': subcategory,
    'color': color,
    'createdAt': createdAt.toIso8601String(),
    'isFavorite': isFavorite,
    'isDemo': isDemo,
  };

  factory Garment.fromJson(Map<String, Object?> json) => Garment(
    id: json['id']! as String,
    originalImagePath: json['originalImagePath']! as String,
    processedImagePath: json['processedImagePath'] as String?,
    category: GarmentCategory.values.byName(json['category']! as String),
    subcategory: json['subcategory']! as String,
    color: json['color'] as String?,
    createdAt: DateTime.parse(json['createdAt']! as String),
    isFavorite: json['isFavorite'] as bool? ?? false,
    isDemo: json['isDemo'] as bool? ?? false,
  );
}
