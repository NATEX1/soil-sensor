import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/sensor_data.dart';

class HistoryTableView extends StatelessWidget {
  final List<MeasurementRecord> measurements;
  const HistoryTableView({super.key, required this.measurements});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.borderColor),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.colors.bgAlt,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Expanded(child: _HeaderText('วันที่')),
                SizedBox(width: 56, child: _HeaderText('พืช', center: true)),
                SizedBox(width: 40, child: _HeaderText('pH', center: true)),
                SizedBox(width: 40, child: _HeaderText('N', center: true)),
                SizedBox(width: 40, child: _HeaderText('P', center: true)),
                SizedBox(width: 40, child: _HeaderText('K', center: true)),
                SizedBox(width: 48, child: _HeaderText('ชื้น%', center: true)),
              ],
            ),
          ),
          ...measurements.asMap().entries.map((entry) {
            final idx = entry.key;
            final m = entry.value;
            final date = m.measuredAt;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: idx % 2 == 0 ? context.colors.cardBg : context.colors.bgAlt,
                border: Border(
                  bottom: BorderSide(
                    color: context.colors.dividerColor,
                    width: idx < measurements.length - 1 ? 1 : 0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (m.pointName?.isNotEmpty == true)
                          Text(
                            m.pointName!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: context.colors.textNormal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          date != null
                              ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}'
                              : '--',
                          style: TextStyle(fontSize: 10, color: context.colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                      width: 56,
                      child: Text(plantTypeLabels[m.plantType] ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: context.colors.textMuted))),
                  SizedBox(
                      width: 40,
                      child: Text(m.ph.toStringAsFixed(1),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: context.colors.textNormal))),
                  SizedBox(
                      width: 40,
                      child: Text(m.nitrogen.round().toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: context.colors.textNormal))),
                  SizedBox(
                      width: 40,
                      child: Text(m.phosphorus.round().toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: context.colors.textNormal))),
                  SizedBox(
                      width: 40,
                      child: Text(m.potassium.round().toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: context.colors.textNormal))),
                  SizedBox(
                      width: 48,
                      child: Text(m.moisture.toStringAsFixed(1),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: context.colors.textNormal))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  final bool center;

  const _HeaderText(this.text, {this.center = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: context.colors.textMuted,
      ),
    );
  }
}
