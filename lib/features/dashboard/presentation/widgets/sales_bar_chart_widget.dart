import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/dashboard_models.dart';

/// Widget grafik batang penjualan harian sederhana dan responsif.
/// Menggunakan standar visual Material 3 tanpa dependensi eksternal yang berat.
class SalesBarChartWidget extends StatelessWidget {
  final List<DailySalesPoint> data;

  const SalesBarChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmpty();
    }

    final maxAmount = data.fold<int>(
      0,
      (max, p) => p.amount > max ? p.amount : max,
    );

    if (maxAmount == 0) {
      return _buildEmpty();
    }

    final dayFormatter = DateFormat('E', 'id_ID');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Chart Area
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: data.map((point) {
              final double ratio = maxAmount > 0
                  ? (point.amount / maxAmount)
                  : 0;
              final isToday = _isSameDay(point.date, DateTime.now());

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Amount label if has value
                      if (point.amount > 0)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formatCompact(point.amount),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isToday
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      // Bar container
                      Flexible(
                        child: FractionallySizedBox(
                          heightFactor: ratio.clamp(0.06, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: point.amount > 0
                                  ? (isToday
                                        ? AppColors.primary
                                        : AppColors.primary.withValues(
                                            alpha: 0.65,
                                          ))
                                  : AppColors.surfaceContainerHighest,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Day label
                      Text(
                        dayFormatter.format(point.date),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isToday
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          const Text(
            'Belum ada transaksi penjualan dalam 7 hari terakhir',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatCompact(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}jt';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toInt()}rb';
    }
    return amount.toString();
  }
}
