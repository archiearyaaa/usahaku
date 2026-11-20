import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/category_model.dart';
import '../data/repositories/category_repository.dart';

class CategoryManageDialog extends StatefulWidget {
  final CategoryRepository? categoryRepository;
  final VoidCallback onCategoriesChanged;

  const CategoryManageDialog({
    super.key,
    this.categoryRepository,
    required this.onCategoriesChanged,
  });

  @override
  State<CategoryManageDialog> createState() => _CategoryManageDialogState();
}

class _CategoryManageDialogState extends State<CategoryManageDialog> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final CategoryRepository _categoryRepo;

  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  CategoryModel? _editingCategory;

  @override
  void initState() {
    super.initState();
    _categoryRepo = widget.categoryRepository ?? CategoryRepository();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final data = await _categoryRepo.getAll();
    if (mounted) {
      setState(() {
        _categories = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    if (_editingCategory != null) {
      await _categoryRepo.update(_editingCategory!.copyWith(name: name));
    } else {
      await _categoryRepo.insert(
        CategoryModel(name: name, createdAt: DateTime.now()),
      );
    }

    _nameController.clear();
    setState(() => _editingCategory = null);
    await _loadCategories();
    widget.onCategoriesChanged();
  }

  Future<void> _confirmDelete(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori?'),
        content: Text(
          'Kategori "${category.name}" akan dihapus. Produk dalam kategori ini akan diatur menjadi tanpa kategori.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && category.id != null) {
      await _categoryRepo.delete(category.id!);
      await _loadCategories();
      widget.onCategoriesChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kelola Kategori',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: _editingCategory != null
                              ? 'Ubah nama kategori'
                              : 'Nama kategori baru',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama wajib diisi';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _saveCategory,
                      child: Text(_editingCategory != null ? 'Ubah' : 'Tambah'),
                    ),
                  ],
                ),
              ),
              if (_editingCategory != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Batal Edit'),
                    onPressed: () {
                      setState(() {
                        _editingCategory = null;
                        _nameController.clear();
                      });
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _categories.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada kategori.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _categories.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              cat.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  color: AppColors.primary,
                                  onPressed: () {
                                    setState(() {
                                      _editingCategory = cat;
                                      _nameController.text = cat.name;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                  ),
                                  color: AppColors.danger,
                                  onPressed: () => _confirmDelete(cat),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
