class Outfit {
  const Outfit({
    required this.id,
    required this.imagePath,
    required this.garmentIds,
    required this.createdAt,
    this.isFavorite = false,
    this.isRemoteImage = false,
  });

  final String id;
  final String imagePath;
  final List<String> garmentIds;
  final DateTime createdAt;
  final bool isFavorite;
  final bool isRemoteImage;

  Outfit copyWith({bool? isFavorite}) => Outfit(
    id: id,
    imagePath: imagePath,
    garmentIds: garmentIds,
    createdAt: createdAt,
    isFavorite: isFavorite ?? this.isFavorite,
    isRemoteImage: isRemoteImage,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'garmentIds': garmentIds,
    'createdAt': createdAt.toIso8601String(),
    'isFavorite': isFavorite,
    'isRemoteImage': isRemoteImage,
  };

  factory Outfit.fromJson(Map<String, Object?> json) => Outfit(
    id: json['id']! as String,
    imagePath: json['imagePath']! as String,
    garmentIds: (json['garmentIds']! as List).cast<String>(),
    createdAt: DateTime.parse(json['createdAt']! as String),
    isFavorite: json['isFavorite'] as bool? ?? false,
    isRemoteImage: json['isRemoteImage'] as bool? ?? false,
  );
}
