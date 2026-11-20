import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../materials/presentation/materials_page.dart';
import 'category_manage_dialog.dart';
import 'products_list_view.dart';

/// Halaman utama tab Produk yang menggabungkan sub-tab Produk dan Bahan Baku.
/// Sesuai ARCHITECTURE.md: menu 3 = "Produk — produk, kategori, dan bahan baku."
class ProductsTabPage extends StatefulWidget {
  const ProductsTabPage({super.key});

  @override
  State<ProductsTabPage> createState() => _ProductsTabPageState();
}

class _ProductsTabPageState extends State<ProductsTabPage> {
  int _refreshKey = 0;

  void _onCategoryChanged() {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Produk & Bahan'),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.category_outlined, size: 18),
              label: const Text('Kategori'),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) => CategoryManageDialog(
                    onCategoriesChanged: _onCategoryChanged,
                  ),
                );
                _onCategoryChanged();
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'Produk'),
              Tab(text: 'Bahan Baku'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ProductsListView(key: ValueKey(_refreshKey)),
            const MaterialsPage(),
          ],
        ),
      ),
    );
  }
}
