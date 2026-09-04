class UserProfile {
  const UserProfile({
    required this.id,
    required this.frontPhotoPath,
    required this.createdAt,
    this.displayName,
    this.sidePhotoPath,
    this.backPhotoPath,
    this.heightCm,
    this.weightKg,
  });

  final String id;
  final String frontPhotoPath;
  final String? displayName;
  final String? sidePhotoPath;
  final String? backPhotoPath;
  final double? heightCm;
  final double? weightKg;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'frontPhotoPath': frontPhotoPath,
    'displayName': displayName,
    'sidePhotoPath': sidePhotoPath,
    'backPhotoPath': backPhotoPath,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, Object?> json) => UserProfile(
    id: json['id']! as String,
    frontPhotoPath: json['frontPhotoPath']! as String,
    displayName: json['displayName'] as String?,
    sidePhotoPath: json['sidePhotoPath'] as String?,
    backPhotoPath: json['backPhotoPath'] as String?,
    heightCm: (json['heightCm'] as num?)?.toDouble(),
    weightKg: (json['weightKg'] as num?)?.toDouble(),
    createdAt: DateTime.parse(json['createdAt']! as String),
  );
}
