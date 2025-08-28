import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit/shared/models/category_model.dart';
import 'package:mataresit/shared/services/category_service.dart';

void main() {
  group('CategoryService', () {
    test('validateCategoryData should return errors for invalid data', () {
      // Test empty name
      final emptyNameRequest = CreateCategoryRequest(name: '');
      final emptyNameErrors = CategoryService.validateCategoryData(emptyNameRequest);
      expect(emptyNameErrors, contains('Category name is required'));

      // Test long name
      final longNameRequest = CreateCategoryRequest(name: 'A' * 51);
      final longNameErrors = CategoryService.validateCategoryData(longNameRequest);
      expect(longNameErrors, contains('Category name cannot exceed 50 characters'));

      // Test invalid color
      final invalidColorRequest = CreateCategoryRequest(
        name: 'Test Category',
        color: 'invalid-color',
      );
      final invalidColorErrors = CategoryService.validateCategoryData(invalidColorRequest);
      expect(invalidColorErrors, contains('Color must be a valid hex color (e.g., #3B82F6)'));
    });

    test('validateCategoryData should return no errors for valid data', () {
      final validRequest = CreateCategoryRequest(
        name: 'Test Category',
        color: '#3B82F6',
        icon: 'tag',
      );
      final errors = CategoryService.validateCategoryData(validRequest);
      expect(errors, isEmpty);
    });

    test('CategoryModel should serialize to/from JSON correctly', () {
      final category = CategoryModel(
        id: 'test-id',
        userId: 'user-id',
        teamId: 'team-id',
        name: 'Test Category',
        color: '#3B82F6',
        icon: 'tag',
        createdAt: DateTime.parse('2023-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2023-01-01T00:00:00Z'),
        receiptCount: 5,
        isTeamCategory: true,
      );

      final json = category.toJson();
      final fromJson = CategoryModel.fromJson(json);

      expect(fromJson.id, equals(category.id));
      expect(fromJson.userId, equals(category.userId));
      expect(fromJson.teamId, equals(category.teamId));
      expect(fromJson.name, equals(category.name));
      expect(fromJson.color, equals(category.color));
      expect(fromJson.icon, equals(category.icon));
      expect(fromJson.receiptCount, equals(category.receiptCount));
      expect(fromJson.isTeamCategory, equals(category.isTeamCategory));
    });

    test('DefaultCategoryColors should contain valid hex colors', () {
      for (final color in DefaultCategoryColors.colors) {
        expect(RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color), isTrue,
            reason: '$color is not a valid hex color');
      }
    });

    test('DefaultCategoryIcons should not be empty', () {
      expect(DefaultCategoryIcons.icons, isNotEmpty);
      expect(DefaultCategoryIcons.icons, contains('tag'));
    });
  });
}
