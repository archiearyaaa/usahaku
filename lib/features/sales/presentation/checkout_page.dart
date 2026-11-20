import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/sale_item_model.dart';
import '../data/models/sale_model.dart';
import '../data/repositories/sale_repository.dart';
import '../data/sales_calculation.dart';

/// Halaman pembayaran kasir: review keranjang, input diskon, metode bayar, uang dibayar, dan simpan transaksi.
class CheckoutPage extends StatefulWidget {
  final List<CartItemModel> cartItems;
  final SaleRepository? saleRepository;

  const CheckoutPage({super.key, required this.cartItems, this.saleRepository});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final SaleRepository _saleRepo;
  late final List<CartItemModel> _items;

  final _discountController = TextEditingController(text: '0');
  final _amountPaidController = TextEditingController();
  final _noteController = TextEditingController();

  String _paymentMethod = 'Tunai';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _saleRepo = widget.saleRepository ?? SaleRepository();
    // Salin list agar modifikasi di halaman checkout tidak merusak list referensi
    _items = widget.cartItems
        .map((e) => CartItemModel(product: e.product, quantity: e.quantity))
        .toList();

    _setDefaultPaymentAmount();
  }

  @override
  void dispose() {
    _discountController.dispose();
    _amountPaidController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int get _subtotal => SalesCalculation.calculateSubtotal(_items);

  int get _discount {
    final parsed = CurrencyFormatter.parse(_discountController.text);
    return parsed.clamp(0, _subtotal);
  }

  int get _total => SalesCalculation.calculateTotal(_subtotal, _discount);

  int get _amountPaid {
    return CurrencyFormatter.parse(_amountPaidController.text);
  }

  int get _changeAmount =>
      SalesCalculation.calculateChange(_total, _amountPaid);

  bool get _canSubmit =>
      _items.isNotEmpty &&
      _total > 0 &&
      SalesCalculation.isPaymentValid(_total, _amountPaid);

  void _setDefaultPaymentAmount() {
    // Default uang pas
    _amountPaidController.text = _total.toString();
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      _items[index].quantity += delta;
      if (_items[index].quantity <= 0) {
        _items.removeAt(index);
      }
      if (_paymentMethod != 'Tunai') {
        _amountPaidController.text = _total.toString();
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      if (_paymentMethod != 'Tunai') {
        _amountPaidController.text = _total.toString();
      }
    });
  }

  void _setAmountPaidQuick(int amount) {
    setState(() {
      _amountPaidController.text = amount.toString();
    });
  }

  Future<void> _processPayment() async {
    if (!_canSubmit) return;

    setState(() => _isProcessing = true);

    try {
      final now = DateTime.now();
      final invoice = await _saleRepo.generateInvoiceNumber(now);

      final sale = SaleModel(
        invoiceNumber: invoice,
        saleDate: now,
        subtotal: _subtotal,
        discount: _discount,
        total: _total,
        paymentMethod: _paymentMethod,
        amountPaid: _amountPaid,
        changeAmount: _changeAmount,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        createdAt: now,
      );

      final saleItems = _items
          .map(
            (e) => SaleItemModel(
              productId: e.product.id,
              productName: e.product.name,
              quantity: e.quantity,
              unitPrice: e.product.sellingPrice,
              unitCost: e.product.costPrice,
              lineTotal: e.lineTotal,
            ),
          )
          .toList();

      final createdSale = await _saleRepo.createSale(
        sale: sale,
        items: saleItems,
      );

      if (mounted) {
        await _showSuccessDialog(createdSale);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan transaksi: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showSuccessDialog(SaleModel sale) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline,
          color: AppColors.success,
          size: 56,
        ),
        title: const Text('Pembayaran Berhasil!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              sale.invoiceNumber,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              CurrencyFormatter.format(sale.total),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            if (sale.paymentMethod == 'Tunai' && sale.changeAmount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Kembalian: ${CurrencyFormatter.format(sale.changeAmount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context, true); // Pop checkout and return success
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(44),
            ),
            child: const Text('Selesai & Transaksi Baru'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pembayaran')),
        body: const Center(
          child: Text(
            'Keranjang belanja kosong',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rincian Item Keranjang
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rincian Pesanan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 4),
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '@ ${CurrencyFormatter.format(item.product.sellingPrice)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Counter
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 20,
                                  ),
                                  color: AppColors.primary,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _updateQuantity(index, -1),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                  ),
                                  color: AppColors.primary,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _updateQuantity(index, 1),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // Line Total
                            SizedBox(
                              width: 80,
                              child: Text(
                                CurrencyFormatter.format(item.lineTotal),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              color: AppColors.textDisabled,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _removeItem(index),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Diskon & Catatan
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _discountController,
                      decoration: const InputDecoration(
                        labelText: 'Diskon (Rp)',
                        hintText: '0',
                        prefixIcon: Icon(Icons.discount_outlined),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) {
                        setState(() {
                          if (_paymentMethod != 'Tunai') {
                            _amountPaidController.text = _total.toString();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Transaksi (opsional)',
                        hintText: 'Contoh: Meja 3, bungkus',
                        prefixIcon: Icon(Icons.notes_outlined),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Metode Pembayaran
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Metode Pembayaran',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: ['Tunai', 'Transfer', 'QRIS'].map((method) {
                        final isSelected = _paymentMethod == method;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(method),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _paymentMethod = method;
                                  if (method != 'Tunai') {
                                    _amountPaidController.text = _total
                                        .toString();
                                  }
                                });
                              },
                              selectedColor: AppColors.primaryContainer,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Pembayaran & Kembalian
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nominal dibayar
                    TextField(
                      controller: _amountPaidController,
                      decoration: InputDecoration(
                        labelText: 'Uang Dibayar (Rp) *',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        errorText: _amountPaid < _total
                            ? 'Nominal kurang dari total belanja'
                            : null,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                    ),

                    if (_paymentMethod == 'Tunai') ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('Uang Pas'),
                            onPressed: () => _setAmountPaidQuick(_total),
                          ),
                          ...[10000, 20000, 50000, 100000]
                              .where((nominal) => nominal >= _total)
                              .map(
                                (nominal) => ActionChip(
                                  label: Text(
                                    CurrencyFormatter.format(nominal),
                                  ),
                                  onPressed: () => _setAmountPaidQuick(nominal),
                                ),
                              ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Ringkasan Angka
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        Text(CurrencyFormatter.format(_subtotal)),
                      ],
                    ),
                    if (_discount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Diskon',
                            style: TextStyle(color: AppColors.danger),
                          ),
                          Text(
                            '- ${CurrencyFormatter.format(_discount)}',
                            style: const TextStyle(color: AppColors.danger),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Belanja',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(_total),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kembalian',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(_changeAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: FilledButton.icon(
            onPressed: (_canSubmit && !_isProcessing) ? _processPayment : null,
            icon: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              _isProcessing
                  ? 'Memproses...'
                  : 'Bayar ${CurrencyFormatter.format(_total)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ),
    );
  }
}
