import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../data/models/material_model.dart';
import '../data/models/stock_movement_model.dart';
import '../data/repositories/material_repository.dart';
import '../data/repositories/stock_movement_repository.dart';

/// Halaman pencatatan stok masuk/keluar dan riwayat pergerakan stok.
class StockMovementPage extends StatefulWidget {
  final MaterialModel material;
  final MaterialRepository? materialRepository;
  final StockMovementRepository? stockMovementRepository;

  const StockMovementPage({
    super.key,
    required this.material,
    this.materialRepository,
    this.stockMovementRepository,
  });

  @override
  State<StockMovementPage> createState() => _StockMovementPageState();
}

class _StockMovementPageState extends State<StockMovementPage> {
  late final MaterialRepository _materialRepo;
  late final StockMovementRepository _movementRepo;

  MaterialModel? _currentMaterial;
  List<StockMovementModel> _movements = [];
  bool _isLoading = true;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _materialRepo = widget.materialRepository ?? MaterialRepository();
    _movementRepo = widget.stockMovementRepository ?? StockMovementRepository();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final material = await _materialRepo.getById(widget.material.id!);
      final movements = await _movementRepo.getByMaterialId(
        widget.material.id!,
      );
      if (mounted) {
        setState(() {
          _currentMaterial = material ?? widget.material;
          _movements = movements;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentMaterial = widget.material;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addMovement(String type) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _StockMovementDialog(
        type: type,
        materialName: _currentMaterial?.name ?? widget.material.name,
        materialUnit: _currentMaterial?.unit ?? widget.material.unit,
        currentQty: _currentMaterial?.quantity ?? widget.material.quantity,
      ),
    );

    if (result == null) return;

    try {
      final now = DateTime.now();
      final movement = StockMovementModel(
        materialId: widget.material.id!,
        type: type,
        quantity: result['quantity'] as double,
        note: result['note'] as String?,
        movementDate: now,
        createdAt: now,
      );

      await _movementRepo.addMovement(movement);
      _hasChanged = true;
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              type == 'in'
                  ? 'Stok masuk berhasil dicatat'
                  : 'Stok keluar berhasil dicatat',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasChanged);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentMaterial?.name ?? widget.material.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanged),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Info stok saat ini
                  _buildStockHeader(),

                  // Tombol Stok Masuk / Keluar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _addMovement('in'),
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Stok Masuk'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.success,
                              side: const BorderSide(color: AppColors.success),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _addMovement('out'),
                            icon: const Icon(Icons.remove_circle_outline),
                            label: const Text('Stok Keluar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Riwayat
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Riwayat Pergerakan Stok',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: _movements.isEmpty
                        ? _buildEmptyHistory()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _movements.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              return _buildMovementTile(_movements[index]);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStockHeader() {
    final mat = _currentMaterial ?? widget.material;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mat.isLowStock
            ? AppColors.warningContainer
            : AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Stok Saat Ini',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatQuantity(mat.quantity)} ${mat.unit}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: mat.isLowStock ? AppColors.warning : AppColors.primary,
                ),
              ),
            ],
          ),
          if (mat.minimumStock != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Stok Minimum',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatQuantity(mat.minimumStock!)} ${mat.unit}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_outlined,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada riwayat pergerakan stok',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementTile(StockMovementModel movement) {
    final isIn = movement.type == 'in';
    final isAdjust = movement.type == 'adjustment';

    final Color iconColor;
    final IconData icon;
    final String prefix;

    if (isIn) {
      iconColor = AppColors.success;
      icon = Icons.add_circle_outline;
      prefix = '+';
    } else if (isAdjust) {
      iconColor = AppColors.info;
      icon = Icons.tune_outlined;
      prefix = '=';
    } else {
      iconColor = AppColors.danger;
      icon = Icons.remove_circle_outline;
      prefix = '-';
    }

    final unit = _currentMaterial?.unit ?? widget.material.unit;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movement.typeLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (movement.note != null && movement.note!.isNotEmpty)
                    Text(
                      movement.note!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    DateFormatter.formatDateTime(movement.movementDate),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$prefix${_formatQuantity(movement.quantity)} $unit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog untuk input jumlah dan catatan stok masuk/keluar.
class _StockMovementDialog extends StatefulWidget {
  final String type;
  final String materialName;
  final String materialUnit;
  final double currentQty;

  const _StockMovementDialog({
    required this.type,
    required this.materialName,
    required this.materialUnit,
    required this.currentQty,
  });

  @override
  State<_StockMovementDialog> createState() => _StockMovementDialogState();
}

class _StockMovementDialogState extends State<_StockMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final isOut = widget.type == 'out';
    final title = isOut ? 'Stok Keluar' : 'Stok Masuk';
    final color = isOut ? AppColors.danger : AppColors.success;

    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.materialName} — '
              'Stok: ${_formatQuantity(widget.currentQty)} ${widget.materialUnit}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _qtyController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Jumlah (${widget.materialUnit}) *',
                hintText: 'Contoh: 5',
                prefixIcon: const Icon(Icons.numbers_outlined),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Jumlah harus diisi';
                }
                final parsed = double.tryParse(val.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Jumlah harus > 0';
                }
                if (isOut && parsed > widget.currentQty) {
                  return 'Melebihi stok tersedia '
                      '(${_formatQuantity(widget.currentQty)})';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'Contoh: Pembelian dari supplier',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'quantity': double.parse(_qtyController.text.trim()),
                'note': _noteController.text.trim().isEmpty
                    ? null
                    : _noteController.text.trim(),
              });
            }
          },
          style: FilledButton.styleFrom(backgroundColor: color),
          child: Text(title),
        ),
      ],
    );
  }
}
