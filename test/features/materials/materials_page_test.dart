import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:usahaku/core/theme/app_theme.dart';
import 'package:usahaku/features/materials/data/models/material_model.dart';
import 'package:usahaku/features/materials/data/repositories/material_repository.dart';
import 'package:usahaku/features/materials/presentation/materials_page.dart';

class FakeMaterialRepository extends MaterialRepository {
  final List<MaterialModel> _items;

  FakeMaterialRepository([List<MaterialModel>? items])
    : _items = items != null ? List.from(items) : [];

  @override
  Future<List<MaterialModel>> getAll({String? searchQuery}) async {
    return _items.where((m) {
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        if (!m.name.toLowerCase().contains(searchQuery.trim().toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Future<int> insert(MaterialModel material) async {
    final newId = _items.length + 1;
    _items.add(material.copyWith(id: newId));
    return newId;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('MaterialsPage Widget Tests', () {
    testWidgets('Menampilkan empty state saat belum ada bahan baku', (
      WidgetTester tester,
    ) async {
      final fakeRepo = FakeMaterialRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MaterialsPage(materialRepository: fakeRepo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada bahan baku'), findsOneWidget);
      expect(find.text('Tambah Bahan'), findsOneWidget);
    });

    testWidgets('Menampilkan daftar bahan baku dan filter pencarian', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final fakeRepo = FakeMaterialRepository([
        MaterialModel(
          id: 1,
          name: 'Gula Pasir',
          unit: 'kg',
          quantity: 15,
          minimumStock: 5,
          createdAt: now,
          updatedAt: now,
        ),
        MaterialModel(
          id: 2,
          name: 'Susu Kental Manis',
          unit: 'kaleng',
          quantity: 2,
          minimumStock: 5, // Stok rendah
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MaterialsPage(materialRepository: fakeRepo),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi list awal
      expect(find.text('Gula Pasir'), findsOneWidget);
      expect(find.text('Susu Kental Manis'), findsOneWidget);
      expect(find.text('Stok Rendah'), findsOneWidget); // Badge stok rendah

      // Cari "Gula"
      await tester.enterText(find.byType(TextField).first, 'Gula');
      await tester.pumpAndSettle();

      expect(find.text('Gula Pasir'), findsOneWidget);
      expect(find.text('Susu Kental Manis'), findsNothing);
    });
  });
}
