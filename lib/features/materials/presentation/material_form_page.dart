import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/material_model.dart';
import '../data/repositories/material_repository.dart';

/// Halaman form tambah/edit bahan baku.
class MaterialFormPage extends StatefulWidget {
  final MaterialModel? material;
  final MaterialRepository? materialRepository;

  const MaterialFormPage({super.key, this.material, this.materialRepository});

  @override
  State<MaterialFormPage> createState() => _MaterialFormPageState();
}

class _MaterialFormPageState extends State<MaterialFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final MaterialRepository _materialRepo;

  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _quantityController;
  late final TextEditingController _minStockController;

  bool _isSaving = false;
  bool get _isEditing => widget.material != null;

  @override
  void initState() {
    super.initState();
    _materialRepo = widget.materialRepository ?? MaterialRepository();

    _nameController = TextEditingController(text: widget.material?.name ?? '');
    _unitController = TextEditingController(text: widget.material?.unit ?? '');
    _quantityController = TextEditingController(
      text: widget.material != null
          ? _formatDouble(widget.material!.quantity)
          : '',
    );
    _minStockController = TextEditingController(
      text: widget.material?.minimumStock != null
          ? _formatDouble(widget.material!.minimumStock!)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  String _formatDouble(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  double? _parseDouble(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final quantity = _parseDouble(_quantityController.text) ?? 0;
      final minStock = _parseDouble(_minStockController.text);

      if (_isEditing) {
        final updated = widget.material!.copyWith(
          name: _nameController.text.trim(),
          unit: _unitController.text.trim(),
          quantity: quantity,
          minimumStock: minStock,
          clearMinimumStock: minStock == null,
          updatedAt: now,
        );
        await _materialRepo.update(updated);
      } else {
        final newMaterial = MaterialModel(
          name: _nameController.text.trim(),
          unit: _unitController.text.trim(),
          quantity: quantity,
          minimumStock: minStock,
          createdAt: now,
          updatedAt: now,
        );
        await _materialRepo.insert(newMaterial);
      }

      if (mounted) {
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
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    if (!_isEditing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Bahan Baku'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${widget.material!.name}"? '
          'Riwayat pergerakan stok juga akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _materialRepo.delete(widget.material!.id!);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Bahan Baku' : 'Tambah Bahan Baku'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.danger,
              tooltip: 'Hapus',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nama Bahan
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Bahan *',
                  hintText: 'Contoh: Gula Pasir',
                  prefixIcon: Icon(Icons.kitchen_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama bahan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Satuan
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Satuan *',
                  hintText: 'Contoh: kg, liter, pcs',
                  prefixIcon: Icon(Icons.straighten_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Satuan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Jumlah Stok
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Stok Awal',
                  hintText: '0',
                  prefixIcon: Icon(Icons.inventory_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final parsed = double.tryParse(val.trim());
                    if (parsed == null || parsed < 0) {
                      return 'Jumlah harus berupa angka >= 0';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Stok Minimum
              TextFormField(
                controller: _minStockController,
                decoration: const InputDecoration(
                  labelText: 'Stok Minimum (opsional)',
                  hintText: 'Batas peringatan stok rendah',
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final parsed = double.tryParse(val.trim());
                    if (parsed == null || parsed < 0) {
                      return 'Stok minimum harus berupa angka >= 0';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Tombol Simpan
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
