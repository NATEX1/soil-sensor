import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/measurements_provider.dart';
import '../widgets/common/error_card.dart';
import '../widgets/history/history_list_view.dart';
import '../theme/app_colors.dart';
import '../widgets/soil_chart.dart';


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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: RefreshIndicator(
        color: context.colors.primaryBtn,
        onRefresh: provider.fetch,
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, bottomPadding + 24),
          children: [
            // — Minimal Header —
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ประวัติการวัด',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: context.colors.textNormal,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 2),
                    Text('${provider.filteredMeasurements.length} รายการ',
                        style: TextStyle(fontSize: 13, color: context.colors.textMuted)),
                  ],
                ),
                TextButton.icon(
                  onPressed: provider.filteredMeasurements.isEmpty
                      ? null
                      : () => _exportToExcel(context, provider),
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.primaryBtn,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Excel',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
                              color: selected ? context.colors.primaryBtn : context.colors.cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: selected ? context.colors.primaryBtn : context.colors.borderColor),
                            ),
                            child: Text(r.label,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        selected ? Colors.white : context.colors.textMuted)),
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
                        color: context.colors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colors.borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: context.colors.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: provider.selectedLocation,
                                hint: Text('ทุกตำแหน่ง',
                                    style: TextStyle(color: context.colors.textMuted)),
                                isExpanded: true,
                                icon: Icon(Icons.arrow_drop_down,
                                    color: context.colors.textMuted),
                                dropdownColor: context.colors.cardBg,
                                style: TextStyle(color: context.colors.textNormal),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('ทุกตำแหน่ง'),
                                  ),
                                  ...provider.uniqueLocations.map((loc) {
                                    return DropdownMenuItem<String>(
                                      value: loc,
                                      child: Text(provider.getLocationName(loc),
                                          style: const TextStyle(fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
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
                        color: context.colors.tabBg, borderRadius: BorderRadius.circular(12)),
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
                          label: 'รายการ',
                          icon: Icons.list_alt_rounded,
                          selected: _activeTab == _ViewTab.table,
                          onTap: () =>
                              setState(() => _activeTab = _ViewTab.table),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (provider.error != null)
                    ErrorCard(
                        message: provider.error!, onRetry: provider.fetch),

                  if (provider.loading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(children: [
                        CircularProgressIndicator(color: context.colors.primaryBtn),
                        const SizedBox(height: 12),
                        Text('กำลังโหลดข้อมูล...',
                            style: TextStyle(color: context.colors.textMuted)),
                      ]),
                    )
                  else if (provider.filteredMeasurements.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(children: [
                        Icon(Icons.inbox_outlined, size: 48, color: context.colors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                            'ยังไม่มีข้อมูลในช่วงเวลานี้\nบันทึกผลการวัดจากแดชบอร์ดก่อน',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.colors.textMuted)),
                      ]),
                    )
                  else if (_activeTab == _ViewTab.chart)
                    SoilChart(measurements: provider.filteredMeasurements)
                  else
                    HistoryListView(measurements: provider.filteredMeasurements),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToExcel(
      BuildContext context, MeasurementsProvider provider) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: const Text('กำลังส่งออก Excel...'),
          backgroundColor: context.colors.successBannerBg),
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? context.colors.tabSelectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16, color: selected ? context.colors.primaryBtn : context.colors.textMuted),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? context.colors.primaryBtn : context.colors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

