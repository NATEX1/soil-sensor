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
                  else
                    HistoryListView(measurements: provider.filteredMeasurements),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToExcel(
      BuildContext context, MeasurementsProvider provider) async {
    final measurements = provider.filteredMeasurements;
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



