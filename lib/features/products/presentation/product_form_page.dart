import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/models/category_model.dart';
import '../data/models/product_bundle_item_model.dart';
import '../data/models/product_model.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/product_repository.dart';

class ProductFormPage extends StatefulWidget {
  final ProductModel? product;
  final ProductRepository productRepository;
  final CategoryRepository categoryRepository;

  const ProductFormPage({
    super.key,
    this.product,
    required this.productRepository,
    required this.categoryRepository,
  });

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _stockController;
  late TextEditingController _unitController;

  int? _selectedCategoryId;
  bool _isActive = true;
  List<CategoryModel> _categories = [];
  List<ProductModel> _allAvailableProducts = [];
  bool _isLoading = true;
  bool _isSaving = false;

  // Fitur Paket Terhubung / Bundling Stock
  bool _isBundle = false;
  List<ProductBundleItemModel> _bundleItems = [];

  bool get _isEditMode => widget.product != null;

  static const List<String> _commonUnits = [
    'porsi',
    'pcs',
    'gelas',
    'cup',
    'buah',
    'bungkus',
    'paket',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _costPriceController = TextEditingController(
      text: p != null ? CurrencyFormatter.formatNumber(p.costPrice) : '0',
    );
    _sellingPriceController = TextEditingController(
      text: p != null ? CurrencyFormatter.formatNumber(p.sellingPrice) : '',
    );
    _stockController = TextEditingController(
      text: p != null ? p.stock.toString() : '0',
    );
    _unitController = TextEditingController(text: p?.unit ?? 'porsi');
    _selectedCategoryId = p?.categoryId;
    _isActive = p?.isActive ?? true;

    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await widget.categoryRepository.seedDefaultCategoriesIfEmpty();
    final cats = await widget.categoryRepository.getAll();
    final prods = await widget.productRepository.getAll();

    List<ProductBundleItemModel> bundles = [];
    if (_isEditMode && widget.product?.id != null) {
      bundles = await widget.productRepository.getBundleItems(
        widget.product!.id!,
      );
    }

    if (mounted) {
      setState(() {
        _categories = cats;
        _allAvailableProducts = prods;
        _bundleItems = bundles;
        _isBundle = bundles.isNotEmpty || (widget.product?.isBundle ?? false);
        _isLoading = false;
      });
    }
  }

  Future<void> _openQuickAddCategory() async {
    final textController = TextEditingController();
    final newCatName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kategori Baru'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama Kategori *',
            hintText: 'Contoh: Paket, Makanan, Minuman',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx, text);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (newCatName != null && newCatName.isNotEmpty) {
      final newCat = CategoryModel(name: newCatName, createdAt: DateTime.now());
      final id = await widget.categoryRepository.insert(newCat);
      final cats = await widget.categoryRepository.getAll();
      if (mounted) {
        setState(() {
          _categories = cats;
          _selectedCategoryId = id;
        });
      }
    }
  }

  int _calculateBundleStock() {
    if (_bundleItems.isEmpty) return 0;
    int minStock = 99999999;
    for (final item in _bundleItems) {
      final available = item.quantity > 0
          ? (item.itemStock / item.quantity).floor()
          : 0;
      if (available < minStock) {
        minStock = available;
      }
    }
    return minStock == 99999999 ? 0 : minStock;
  }

  void _autoCalculateBundleHpp() {
    int total = 0;
    for (final item in _bundleItems) {
      total += item.itemCostPrice * item.quantity;
    }
    setState(() {
      _costPriceController.text = CurrencyFormatter.formatNumber(total);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'HPP dihitung otomatis: ${CurrencyFormatter.format(total)}',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _showAddBundleItemDialog() async {
    final otherProducts = _allAvailableProducts.where((p) {
      if (widget.product?.id != null && p.id == widget.product!.id) {
        return false;
      }
      return true;
    }).toList();

    if (otherProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Belum ada produk lain yang dapat dimasukkan ke dalam paket.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    ProductModel selectedProduct = otherProducts.first;
    int qty = 1;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Pilih Produk untuk Paket'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Produk:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: selectedProduct.id,
                    isExpanded: true,
                    items: otherProducts.map((p) {
                      return DropdownMenuItem<int>(
                        value: p.id,
                        child: Text('${p.name} (Stok: ${p.stock} ${p.unit})'),
                      );
                    }).toList(),
                    onChanged: (id) {
                      setDialogState(() {
                        selectedProduct = otherProducts.firstWhere(
                          (p) => p.id == id,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Jumlah Per Paket:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove),
                        onPressed: qty > 1
                            ? () => setDialogState(() => qty--)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$qty ${selectedProduct.unit}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add),
                        onPressed: () => setDialogState(() => qty++),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final existingIndex = _bundleItems.indexWhere(
                      (i) => i.itemProductId == selectedProduct.id,
                    );
                    setState(() {
                      if (existingIndex >= 0) {
                        _bundleItems[existingIndex] =
                            _bundleItems[existingIndex].copyWith(
                              quantity: qty,
                              itemStock: selectedProduct.stock,
                            );
                      } else {
                        _bundleItems.add(
                          ProductBundleItemModel(
                            bundleProductId: widget.product?.id ?? 0,
                            itemProductId: selectedProduct.id!,
                            itemName: selectedProduct.name,
                            itemUnit: selectedProduct.unit,
                            itemCostPrice: selectedProduct.costPrice,
                            itemStock: selectedProduct.stock,
                            quantity: qty,
                          ),
                        );
                      }
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Tambahkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isBundle && _bundleItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Produk paket harus memiliki minimal 1 produk komponen.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    final costPrice = CurrencyFormatter.parse(_costPriceController.text);
    final sellingPrice = CurrencyFormatter.parse(_sellingPriceController.text);
    final unit = _unitController.text.trim().isEmpty
        ? 'porsi'
        : _unitController.text.trim();
    final stock = _isBundle
        ? _calculateBundleStock()
        : (int.tryParse(_stockController.text.trim()) ?? 0);
    final now = DateTime.now();

    try {
      int savedProductId;
      if (_isEditMode) {
        final updated = widget.product!.copyWith(
          categoryId: _selectedCategoryId,
          name: name,
          description: desc.isEmpty ? null : desc,
          costPrice: costPrice,
          sellingPrice: sellingPrice,
          stock: stock,
          unit: unit,
          isBundle: _isBundle,
          isActive: _isActive,
          updatedAt: now,
        );
        await widget.productRepository.update(updated);
        savedProductId = widget.product!.id!;
      } else {
        final newProduct = ProductModel(
          categoryId: _selectedCategoryId,
          name: name,
          description: desc.isEmpty ? null : desc,
          costPrice: costPrice,
          sellingPrice: sellingPrice,
          stock: stock,
          unit: unit,
          isBundle: _isBundle,
          isActive: _isActive,
          createdAt: now,
          updatedAt: now,
        );
        savedProductId = await widget.productRepository.insert(newProduct);
      }

      // Simpan komponen bundle
      await widget.productRepository.saveBundleItems(
        savedProductId,
        _isBundle ? _bundleItems : [],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Produk berhasil diperbarui'
                  : 'Produk berhasil ditambahkan',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: Text(
          'Produk "${widget.product!.name}" akan dihapus. Riwayat transaksi sebelumnya tetap aman.',
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

    if (confirmed == true && widget.product?.id != null) {
      await widget.productRepository.delete(widget.product!.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil dihapus'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Produk' : 'Tambah Produk'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.danger,
              onPressed: _deleteProduct,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Nama Produk
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Produk *',
                      hintText:
                          'Contoh: Es Teh Manis, Nasi Goreng, Paket Misopa',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nama produk wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Kategori Dropdown + Quick Add Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          initialValue: _selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Kategori (Opsional)',
                            helperText:
                                'Pilih kategori (misal: Paket, Makanan)',
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Tanpa Kategori'),
                            ),
                            ..._categories.map(
                              (c) => DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedCategoryId = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: IconButton.filledTonal(
                          icon: const Icon(Icons.add),
                          tooltip: 'Tambah Kategori Baru',
                          onPressed: _openQuickAddCategory,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Satuan Produk (Porsi, Pcs, Gelas, dll)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Satuan Produk',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _commonUnits.map((u) {
                          final isSelected =
                              _unitController.text.trim().toLowerCase() == u;
                          return ChoiceChip(
                            label: Text(u),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _unitController.text = u;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Ketik Satuan Lain (Opsional)',
                          hintText: 'Contoh: porsi, pcs, gelas, botol',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Harga Jual (Wajib)
                  TextFormField(
                    controller: _sellingPriceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Harga Jual (Rp) *',
                      hintText: 'Contoh: 15000',
                      prefixText: 'Rp ',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Harga jual wajib diisi';
                      }
                      final parsed = CurrencyFormatter.parse(val);
                      if (parsed <= 0) {
                        return 'Harga jual harus lebih besar dari 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Harga Modal / HPP
                  TextFormField(
                    controller: _costPriceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Harga Modal / HPP (Rp)',
                      hintText: 'Contoh: 10000',
                      prefixText: 'Rp ',
                      helperText:
                          'Estimasi modal produk atau total modal isi paket',
                    ),
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty) {
                        final parsed = CurrencyFormatter.parse(val);
                        if (parsed < 0) {
                          return 'Harga modal tidak boleh negatif';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Fitur Paket Terhubung / Bundling Stock
                  Card(
                    elevation: 0,
                    color: _isBundle
                        ? AppColors.primaryContainer.withValues(alpha: 0.35)
                        : Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _isBundle
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        width: _isBundle ? 1.5 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Jadikan Menu Paket / Kombo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: const Text(
                              'Stok paket otomatis mengikuti sisa stok produk penyusunnya (misal: Misopa 120 pcs)',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            value: _isBundle,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() {
                                _isBundle = val;
                                if (val) {
                                  _unitController.text = 'paket';
                                  final paketCat = _categories
                                      .where(
                                        (c) => c.name.toLowerCase() == 'paket',
                                      )
                                      .firstOrNull;
                                  if (paketCat != null) {
                                    _selectedCategoryId = paketCat.id;
                                  }
                                }
                              });
                            },
                          ),
                          if (_isBundle) ...[
                            const Divider(height: 16),
                            const Text(
                              'Produk Komponen Penyusun Paket:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_bundleItems.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.amber.shade300,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Belum ada produk komponen. Tambahkan produk penyusun (misal: Misopa 1 pcs).',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else ...[
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _bundleItems.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 8),
                                itemBuilder: (context, index) {
                                  final item = _bundleItems[index];
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      '${item.itemName} (${item.quantity} ${item.itemUnit})',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Sisa stok fisik: ${item.itemStock} ${item.itemUnit} | Modal: ${CurrencyFormatter.format(item.itemCostPrice * item.quantity)}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.danger,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _bundleItems.removeAt(index);
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Stok Paket Tersedia: ${_calculateBundleStock()} paket\n(Otomatis mengikuti sisa persediaan fisik)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Tambah Isi Paket'),
                                    onPressed: _showAddBundleItemDialog,
                                  ),
                                ),
                                if (_bundleItems.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    icon: const Icon(
                                      Icons.calculate_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Hitung HPP'),
                                    onPressed: _autoCalculateBundleHpp,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stok Produk Jadi (Hanya jika bukan paket)
                  if (!_isBundle) ...[
                    TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText:
                            'Stok Persediaan (${_unitController.text.trim().isEmpty ? 'porsi' : _unitController.text.trim()})',
                        hintText: 'Contoh: 120',
                        helperText: 'Jumlah persediaan fisik siap jual',
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Deskripsi
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi / Catatan (Opsional)',
                      hintText:
                          'Misal: rincian menu atau porsi (Misopa + Es Teh)',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Aktif Switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Produk Aktif',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _isActive
                          ? 'Produk akan muncul di menu kasir'
                          : 'Produk disembunyikan dari menu kasir',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    activeThumbColor: AppColors.primary,
                    value: _isActive,
                    onChanged: (val) {
                      setState(() => _isActive = val);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Tombol Simpan
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProduct,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEditMode ? 'Simpan Perubahan' : 'Tambah Produk',
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
