import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/history_stats.dart';

class YearToDateStatsCard extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final HistoryStats stats;

  const YearToDateStatsCard({
    super.key,
    required this.stats,
    this.startDate,
    this.endDate,
  });

  String _getDateRangeText() {
    if (startDate == null || endDate == null) {
      return 'Tüm Zamanlar Toplam';
    }
    if (startDate?.year == endDate?.year) {
      return '${startDate?.year} Yılı Toplam';
    }
    final dateFormat = DateFormat('dd.MM.yyyy');
    return '${dateFormat.format(startDate!)} - ${dateFormat.format(endDate!)}';
  }

  String _formatConsumption(double value) {
    // 6 basamaktan büyükse ondalık kısmı gösterme
    if (value.abs() >= 100000) {
      return '${value.round()} kWh';
    }
    return '${value.toStringAsFixed(1)} kWh';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getDateRangeText(),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              stats.formattedPrice,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _StatTile(
              title: 'Toplam Tüketim',
              value: _formatConsumption(stats.totalConsumptionKWh),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(102), Colors.transparent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
