import 'package:flutter_test/flutter_test.dart';

import 'package:simsrl/models/outfit.dart';

void main() {
  test('outfit serializes its selected garments', () {
    final outfit = Outfit(
      id: 'outfit-1',
      imagePath: '/private/outfit.jpg',
      garmentIds: const ['top-1', 'bottom-1'],
      createdAt: DateTime.utc(2026, 9, 4),
    );

    final decoded = Outfit.fromJson(outfit.toJson());

    expect(decoded.garmentIds, ['top-1', 'bottom-1']);
    expect(decoded.isFavorite, isFalse);
    expect(decoded.copyWith(isFavorite: true).isFavorite, isTrue);
  });
}
