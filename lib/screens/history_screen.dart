import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/measurements_provider.dart';
import '../widgets/common/error_card.dart';
import '../widgets/history/history_list_view.dart';
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
            child: ListView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: EdgeInsets.fromLTRB(
                isTablet ? 40 : 20, 
                topPadding + 20, 
                isTablet ? 40 : 20, 
                bottomPadding + 24
              ),
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
                    children: DateRange.values.map((r) {
                      final selected = provider.dateRange == r;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => provider.setDateRange(r),
                          child: AnimatedContainer(
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
                              r.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : context.colors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
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
                else if (provider.measurements.isEmpty)
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
                  )
                else ...[
                  HistoryListView(measurements: provider.measurements),
                  if (provider.loadingMore)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(color: context.colors.primaryBtn, strokeWidth: 2),
                      ),
                    ),
                  if (!provider.hasMore && provider.measurements.length > 5)
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton(BuildContext context, MeasurementsProvider provider) {
    final isEmpty = provider.allMeasurements.isEmpty;
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
    final measurements = provider.allMeasurements;
    if (measurements.isEmpty) {
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
        TextCellValue('พืช'),
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
      for (var m in measurements) {
        String dateStr = m.measuredAt != null 
            ? '${m.measuredAt!.day}/${m.measuredAt!.month}/${m.measuredAt!.year} ${m.measuredAt!.hour}:${m.measuredAt!.minute.toString().padLeft(2, '0')}' 
            : '-';
        
        sheetObject.appendRow([
          TextCellValue(dateStr),
          TextCellValue(m.pointName ?? '-'),
          TextCellValue(m.plantName),
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
}



