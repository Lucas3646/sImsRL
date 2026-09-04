import 'package:flutter_test/flutter_test.dart';

import 'package:simsrl/models/garment.dart';

void main() {
  test('garment survives a JSON round trip', () {
    final garment = Garment(
      id: 'g1',
      originalImagePath: '/private/tshirt.jpg',
      processedImagePath: '/private/tshirt-cutout.png',
      category: GarmentCategory.tops,
      subcategory: 'T-shirt',
      color: 'Blanc',
      createdAt: DateTime.utc(2026, 9, 4),
      isFavorite: true,
    );

    final decoded = Garment.fromJson(garment.toJson());

    expect(decoded.id, garment.id);
    expect(decoded.category, GarmentCategory.tops);
    expect(decoded.displayImagePath, '/private/tshirt-cutout.png');
    expect(decoded.isFavorite, isTrue);
  });

  test('category exposes extensible subcategories', () {
    expect(
      GarmentCategory.bottoms.subcategories,
      containsAll(['Jean', 'Pantalon']),
    );
    expect(GarmentCategory.shoes.label, 'Chaussures');
  });
}
