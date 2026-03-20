import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/measurements_provider.dart';
import '../models/sensor_data.dart';
import '../widgets/soil_chart.dart';

const _green600 = Color(0xFF16a34a);

enum _ViewTab { chart, table }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _ViewTab _activeTab = _ViewTab.chart;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeasurementsProvider>();
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final headerBg = isDark ? const Color(0xFF1f2937) : const Color(0xFF16a34a);
    final headerSubtitle =
        isDark ? const Color(0xFF6b7280) : const Color(0xFFbbf7d0);
    final primaryBtn =
        isDark ? const Color(0xFF15803d) : const Color(0xFF16a34a);
    final tabBg = isDark ? const Color(0xFF1f2937) : const Color(0xFFf3f4f6);
    final tabInactive =
        isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280);
    final cardBg = isDark ? const Color(0xFF1f2937) : Colors.white;
    final textMuted =
        isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280);
    final textNormal =
        isDark ? const Color(0xFFe5e7eb) : const Color(0xFF374151);
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb);
    final bgAlt = isDark ? const Color(0xFF111827) : const Color(0xFFf9fafb);
    final errorBg = isDark ? const Color(0xFF450a0a) : const Color(0xFFfef2f2);
    final errorBorder =
        isDark ? const Color(0xFF991b1b) : const Color(0xFFfecaca);
    final errorText =
        isDark ? const Color(0xFFfca5a5) : const Color(0xFFb91c1c);

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: headerBg,
            padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart,
                        color: isDark ? const Color(0xFF4ade80) : Colors.white,
                        size: 24),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ประวัติการวัด',
                            style: TextStyle(
                                color: isDark
                                    ? const Color(0xFFf9fafb)
                                    : Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('${provider.filteredMeasurements.length} รายการ',
                            style:
                                TextStyle(color: headerSubtitle, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: provider.filteredMeasurements.isEmpty
                      ? null
                      : () => _exportToExcel(context, provider),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    shape: const StadiumBorder(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('ส่งออก Excel',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              color: Theme.of(context).brightness == Brightness.dark
                  ? headerBg
                  : _green600,
              onRefresh: provider.fetch,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date range filter
                  Row(
                    children: DateRange.values.map((r) {
                      final selected = provider.dateRange == r;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => provider.setDateRange(r),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? primaryBtn : cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: selected ? primaryBtn : borderColor),
                            ),
                            child: Text(r.label,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        selected ? Colors.white : textMuted)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Location filter
                  if (provider.uniqueLocations.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: provider.selectedLocation,
                                hint: Text('ทุกตำแหน่ง',
                                    style: TextStyle(color: textMuted)),
                                isExpanded: true,
                                icon: Icon(Icons.arrow_drop_down,
                                    color: textMuted),
                                dropdownColor: cardBg,
                                style: TextStyle(color: textNormal),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('ทุกตำแหน่ง'),
                                  ),
                                  ...provider.uniqueLocations.map((loc) {
                                    return DropdownMenuItem<String>(
                                      value: loc,
                                      child: Text(loc,
                                          style: TextStyle(fontSize: 13)),
                                    );
                                  }),
                                ],
                                onChanged: (val) => provider.setLocation(val),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (provider.uniqueLocations.isNotEmpty)
                    const SizedBox(height: 12),

                  // View tabs
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: tabBg, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        _TabButton(
                          label: 'กราฟ',
                          icon: Icons.trending_up,
                          selected: _activeTab == _ViewTab.chart,
                          onTap: () =>
                              setState(() => _activeTab = _ViewTab.chart),
                        ),
                        _TabButton(
                          label: 'ตาราง',
                          icon: Icons.table_chart_outlined,
                          selected: _activeTab == _ViewTab.table,
                          onTap: () =>
                              setState(() => _activeTab = _ViewTab.table),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (provider.error != null)
                    _ErrorCard(
                        message: provider.error!, onRetry: provider.fetch),

                  if (provider.loading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(children: [
                        CircularProgressIndicator(color: primaryBtn),
                        const SizedBox(height: 12),
                        Text('กำลังโหลดข้อมูล...',
                            style: TextStyle(color: textMuted)),
                      ]),
                    )
                  else if (provider.filteredMeasurements.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(children: [
                        Icon(Icons.inbox_outlined, size: 48, color: textMuted),
                        const SizedBox(height: 12),
                        Text(
                            'ยังไม่มีข้อมูลในช่วงเวลานี้\nบันทึกผลการวัดจากแดชบอร์ดก่อน',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textMuted)),
                      ]),
                    )
                  else if (_activeTab == _ViewTab.chart)
                    SoilChart(measurements: provider.filteredMeasurements)
                  else
                    _TableView(measurements: provider.filteredMeasurements),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToExcel(
      BuildContext context, MeasurementsProvider provider) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final snackBg = isDark ? const Color(0xFF052e16) : const Color(0xFF16a34a);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: const Text('กำลังส่งออก Excel...'),
          backgroundColor: snackBg),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor =
        isDark ? const Color(0xFF22c55e) : const Color(0xFF16a34a);
    final unselectedColor =
        isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? const Color(0xFF374151) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06), blurRadius: 4)
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16, color: selected ? selectedColor : unselectedColor),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? selectedColor : unselectedColor)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableView extends StatelessWidget {
  final List<MeasurementRecord> measurements;
  const _TableView({required this.measurements});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1f2937) : Colors.white;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFf9fafb);
    final headerText =
        isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280);
    final valueText =
        isDark ? const Color(0xFFe5e7eb) : const Color(0xFF374151);
    final dividerColor =
        isDark ? const Color(0xFF1f2937) : const Color(0xFFf3f4f6);
    final rowBgAlt = isDark ? const Color(0xFF1f2937) : const Color(0xFFf9fafb);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb)),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                    child: Text('วันที่',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: headerText))),
                SizedBox(
                    width: 56,
                    child: Text('พืช',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: headerText))),
                SizedBox(
                    width: 40,
                    child: Text('pH',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: headerText))),
                SizedBox(
                    width: 40,
                    child: Text('N',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: headerText))),
                SizedBox(
                    width: 40,
                    child: Text('P',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: headerText))),
                SizedBox(
                    width: 40,
                    child: Text('K',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: headerText))),
                SizedBox(
                    width: 48,
                    child: Text('ชื้น%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: headerText))),
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
                color: idx % 2 == 0 ? cardColor : rowBgAlt,
                border: Border(
                    bottom: BorderSide(
                        color: dividerColor,
                        width: idx < measurements.length - 1 ? 1 : 0)),
              ),
              child: Row(
                children: [
                  Expanded(
                      child: Text(
                    date != null
                        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}'
                        : '--',
                    style: TextStyle(fontSize: 11, color: headerText),
                  )),
                  SizedBox(
                      width: 56,
                      child: Text(plantTypeLabels[m.plantType] ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: headerText))),
                  SizedBox(
                      width: 40,
                      child: Text(m.ph.toStringAsFixed(1),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: valueText))),
                  SizedBox(
                      width: 40,
                      child: Text(m.nitrogen.round().toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: valueText))),
                  SizedBox(
                      width: 40,
                      child: Text(m.phosphorus.round().toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: valueText))),
                  SizedBox(
                      width: 40,
                      child: Text(m.potassium.round().toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: valueText))),
                  SizedBox(
                      width: 48,
                      child: Text(m.moisture.toStringAsFixed(1),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: valueText))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorBg = isDark ? const Color(0xFF450a0a) : const Color(0xFFfef2f2);
    final errorBorder =
        isDark ? const Color(0xFF991b1b) : const Color(0xFFfecaca);
    final errorText =
        isDark ? const Color(0xFFfca5a5) : const Color(0xFFb91c1c);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.error_outline, size: 16, color: errorText),
            const SizedBox(width: 8),
            Expanded(
                child: Text(message,
                    style: TextStyle(color: errorText, fontSize: 13))),
          ]),
          GestureDetector(
            onTap: onRetry,
            child: Padding(
              padding: const EdgeInsets.only(top: 6, left: 24),
              child: Text('ลองใหม่',
                  style: TextStyle(
                      color: errorText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline)),
            ),
          ),
        ],
      ),
    );
  }
}
