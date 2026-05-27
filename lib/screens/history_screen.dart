import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/measurements_provider.dart';
import '../providers/plot_provider.dart';
import '../widgets/common/error_card.dart';
import '../widgets/history/history_list_view.dart';
import '../widgets/history/history_chart.dart';
import '../models/sensor_data.dart';
import '../theme/app_colors.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<MeasurementsProvider>().fetchMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeasurementsProvider>();
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final maxContentWidth = isTablet ? 800.0 : double.infinity;

    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      body: RefreshIndicator(
        color: context.colors.primaryBtn,
        onRefresh: provider.fetch,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isTablet ? 40 : 20, 
                      topPadding + 20, 
                      isTablet ? 40 : 20, 
                      0
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        Text('${provider.totalCount} รายการ',
                            style: TextStyle(fontSize: 13, color: context.colors.textMuted)),
                      ],
                    ),
                    _buildExportButton(context, provider),
                  ],
                ),
                const SizedBox(height: 24),
                
                // — Date Range Selector (Modern Chips) —
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      // If custom is selected, show it as the first chip
                      if (provider.dateRange == DateRange.custom && provider.customFrom != null && provider.customTo != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => _showCustomDateSheet(context, provider),
                            child: _buildChipContainer(
                              context: context,
                              label: '${provider.customFrom!.day.toString().padLeft(2, '0')}/${provider.customFrom!.month.toString().padLeft(2, '0')}/${provider.customFrom!.year} - ${provider.customTo!.day.toString().padLeft(2, '0')}/${provider.customTo!.month.toString().padLeft(2, '0')}/${provider.customTo!.year}',
                              selected: true,
                            ),
                          ),
                        ),
                      ...DateRange.values.where((r) => r != DateRange.custom).map((r) {
                        final selected = provider.dateRange == r;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => provider.setDateRange(r),
                            child: _buildChipContainer(
                              context: context,
                              label: r.label,
                              selected: selected,
                            ),
                          ),
                        );
                      }),
                      if (provider.dateRange != DateRange.custom)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => _showCustomDateSheet(context, provider),
                            child: _buildChipContainer(
                              context: context,
                              label: 'กำหนดเอง',
                              selected: false,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // — Historical Trend Chart —
                if (provider.allPlots.length >= 2)
                  HistoryChart(plots: provider.allPlots),
                if (provider.allPlots.length >= 2)
                  const SizedBox(height: 24),

                if (provider.error != null)
                  ErrorCard(message: provider.error!, onRetry: provider.fetch)
                else if (provider.loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: context.colors.primaryBtn, strokeWidth: 3),
                          const SizedBox(height: 16),
                          Text('กำลังโหลดข้อมูล...', style: TextStyle(color: context.colors.textMuted, fontSize: 14)),
                        ],
                      ),
                    ),
                  )
                else if (provider.plots.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.history_rounded, size: 64, color: context.colors.textMuted.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'ไม่พบประวัติการวัด\nในช่วงเวลาที่เลือก',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.colors.textMuted, fontSize: 15, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                      ],
                    ),
                  ),
                ),
                if (provider.error == null && !provider.loading && provider.plots.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 20),
                    sliver: HistoryListView(
                      plots: provider.plots,
                      onDelete: (id) {
                        provider.remove(id);
                        context.read<PlotProvider>().loadAvailablePlots();
                      },
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isTablet ? 40 : 20, 
                      0, 
                      isTablet ? 40 : 20, 
                      bottomPadding + 24
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  if (provider.loadingMore)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(color: context.colors.primaryBtn, strokeWidth: 2),
                      ),
                    ),
                  if (!provider.hasMore && provider.plots.length > 5)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          '— สิ้นสุดรายการ —',
                          style: TextStyle(color: context.colors.textMuted, fontSize: 12),
                        ),
                      ),
                    ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton(BuildContext context, MeasurementsProvider provider) {
    final isEmpty = provider.allPlots.isEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEmpty ? null : () => _exportToExcel(context, provider),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: context.colors.borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.ios_share_rounded, size: 16, color: isEmpty ? context.colors.textMuted : context.colors.primaryBtn),
              const SizedBox(width: 6),
              Text('ส่งออก Excel', 
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w700, 
                    color: isEmpty ? context.colors.textMuted : context.colors.textNormal
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportToExcel(
      BuildContext context, MeasurementsProvider provider) async {
    final plots = provider.allPlots;
    if (plots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('ไม่มีข้อมูลสำหรับส่งออก', style: TextStyle(color: context.colors.errorText)),
            backgroundColor: context.colors.errorBg),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
            'กำลังเตรียมไฟล์ Excel...',
            style: TextStyle(color: context.colors.successBannerText),
          ),
          backgroundColor: context.colors.successBannerBg),
    );

    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];
      excel.setDefaultSheet('Sheet1');

      // Add Header
      sheetObject.appendRow([
        TextCellValue('วันที่/เวลา'),
        TextCellValue('จุดที่เก็บ'),
        TextCellValue('แปลง'),
        TextCellValue('วิธีเก็บตัวอย่าง'),
        TextCellValue('ละติจูด (Lat)'),
        TextCellValue('ลองจิจูด (Lng)'),
        TextCellValue('หมายเหตุ'),
        TextCellValue('pH'),
        TextCellValue('ไนโตรเจน (mg/kg)'),
        TextCellValue('ฟอสฟอรัส (mg/kg)'),
        TextCellValue('โพแทสเซียม (mg/kg)'),
        TextCellValue('ความชื้น (%)'),
        TextCellValue('อุณหภูมิ (°C)'),
        TextCellValue('EC (dS/m)'),
        TextCellValue('ความเค็ม (ppt)'),
      ]);

      // Add Data
      for (var p in plots) {
        for (var m in p.measurements) {
          String dateStr = m.measuredAt != null 
              ? '${m.measuredAt!.day}/${m.measuredAt!.month}/${m.measuredAt!.year} ${m.measuredAt!.hour}:${m.measuredAt!.minute.toString().padLeft(2, '0')}' 
              : '-';
          
          sheetObject.appendRow([
            TextCellValue(dateStr),
            TextCellValue(m.pointName ?? '-'),
            TextCellValue(p.name),
            TextCellValue(sampleMethodLabels[m.sampleMethod] ?? '-'),
            DoubleCellValue(m.lat),
            DoubleCellValue(m.lng),
            TextCellValue(m.notes ?? '-'),
            DoubleCellValue(m.ph),
            DoubleCellValue(m.nitrogen),
            DoubleCellValue(m.phosphorus),
            DoubleCellValue(m.potassium),
            DoubleCellValue(m.moisture),
            DoubleCellValue(m.temperature),
            DoubleCellValue(m.ec),
            DoubleCellValue(m.salinity),
          ]);
        }
      }

      var fileBytes = excel.save();
      if (fileBytes == null) throw Exception("Failed to save excel file");
      
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/SoilSensor_Export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      
      File file = File(filePath);
      await file.writeAsBytes(fileBytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        await Share.shareXFiles([XFile(filePath)], text: 'ข้อมูลเซ็นเซอร์ดิน');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาดในการส่งออก: $e', style: TextStyle(color: context.colors.errorText)),
              backgroundColor: context.colors.errorBg),
        );
      }
    }
  }

  Widget _buildChipContainer({required BuildContext context, required String label, required bool selected}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? context.colors.primaryBtn : context.colors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? context.colors.primaryBtn : context.colors.borderColor,
          width: 1.5,
        ),
        boxShadow: selected ? [
          BoxShadow(
            color: context.colors.primaryBtn.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : context.colors.textMuted,
        ),
      ),
    );
  }

  void _showCustomDateSheet(BuildContext context, MeasurementsProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomDateSheet(provider: provider),
    );
  }
}

// ─── Custom Date Filter Bottom Sheet ────────────────────────────────────────

class _CustomDateSheet extends StatefulWidget {
  final MeasurementsProvider provider;

  const _CustomDateSheet({required this.provider});

  @override
  State<_CustomDateSheet> createState() => _CustomDateSheetState();
}

class _CustomDateSheetState extends State<_CustomDateSheet> {
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    if (widget.provider.dateRange == DateRange.custom) {
      _start = widget.provider.customFrom;
      _end = widget.provider.customTo;
    } else {
      _start = DateTime.now().subtract(const Duration(days: 30));
      _end = DateTime.now();
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final initialDate = isStart ? (_start ?? DateTime.now()) : (_end ?? DateTime.now());
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark ? const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Color(0xFF1f2937),
              onSurface: Colors.white,
            ) : const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
          if (_end != null && _start!.isAfter(_end!)) {
            _end = _start;
          }
        } else {
          _end = picked;
          if (_start != null && _end!.isBefore(_start!)) {
            _start = _end;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('กำหนดช่วงเวลา',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: context.colors.textNormal)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: context.colors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: 'วันที่เริ่มต้น',
                    date: _start,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DateButton(
                    label: 'วันที่สิ้นสุด',
                    date: _end,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (_start != null && _end != null) ? () {
                  widget.provider.setCustomRange(_start!, _end!);
                  Navigator.pop(context);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primaryBtn,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: context.colors.borderColor,
                ),
                child: const Text('ตกลง', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateButton({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = date;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textMuted)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: context.colors.borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  d != null ? '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}' : '-',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.colors.textNormal),
                ),
                Icon(Icons.calendar_month_rounded, size: 18, color: context.colors.primaryBtn),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
