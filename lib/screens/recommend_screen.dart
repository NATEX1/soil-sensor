import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/sensor_data.dart';
import '../models/calculations.dart';
import '../providers/measurements_provider.dart';
import '../providers/plot_provider.dart';
import '../theme/app_colors.dart';

class RecommendScreen extends StatefulWidget {
  final PlotRecord? plot;
  const RecommendScreen({super.key, this.plot});

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  PlotRecord? get plot => widget.plot;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    if (plot == null || plot!.measurements.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sensors_off, size: 48, color: context.colors.textMuted),
              const SizedBox(height: 12),
              Text('ไม่มีข้อมูลแปลง\nกรุณาบันทึกค่าอย่างน้อย 1 จุด',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.textMuted)),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () => context.pop(),
                    style: TextButton.styleFrom(foregroundColor: context.colors.primaryBtn),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('กลับ'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      side: BorderSide(color: Colors.red.shade300),
                    ),
                    icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade400),
                    label: const Text('ลบแปลง'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final top3 = evaluateSuitability(plot!);

    return Scaffold(
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 32),
        children: [
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.arrow_back_ios_new, size: 20, color: context.colors.textNormal),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _confirmDelete(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.delete_outline_rounded, size: 22, color: Colors.red.shade400),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text('ผลการวิเคราะห์',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: context.colors.textNormal,
                  letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text('แปลง: ${plot!.name}  •  ${plot!.measurementCount} จุดวัด',
              style: TextStyle(fontSize: 13, color: context.colors.textMuted)),

          const SizedBox(height: 20),

          // ── Measurement Points List ──
          _MeasurementList(measurements: plot!.measurements),

          const SizedBox(height: 20),

          // ── Browse all varieties button ──
          OutlinedButton.icon(
            onPressed: () => _showAllSheet(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.primaryBtn,
              side: BorderSide(color: context.colors.borderColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.list_alt_rounded, size: 18),
            label: Text(
              'เปรียบเทียบสายพันธุ์ทั้งหมด (${cassavaVarieties.length} ชนิด)',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),

          const SizedBox(height: 24),

          // ── Section title ──
          Row(
            children: [
              Text('ความเหมาะสม 3 อันดับแรก',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textNormal)),
            ],
          ),
          const SizedBox(height: 4),
          Text('คำนวณจากค่าเฉลี่ยแปลง',
              style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
          const SizedBox(height: 14),

          // ── Top 3 Cassava cards ──
          ...top3.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final s = entry.value;
            final variety = cassavaVarieties[s.plantId];
            return _CassavaCard(suitability: s, rank: rank, variety: variety, plot: plot!);
          }),

        ],
      ),
    );
  }

  void _showAllSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AllVarietiesSheet(plot: plot!),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('ลบแปลง',
            style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textNormal)),
        content: Text(
          plot!.measurementCount > 0
              ? 'ลบ "${plot!.name}" และการวัดทั้งหมด ${plot!.measurementCount} จุด?'
              : 'ลบ "${plot!.name}" (ไม่มีข้อมูลบันทึก)?',
          style: TextStyle(color: context.colors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ยกเลิก', style: TextStyle(color: context.colors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MeasurementsProvider>().remove(plot!.id);
              context.read<PlotProvider>().loadAvailablePlots();
              context.pop();
            },
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }
}

// ─── Measurement List ─────────────────────────────────────────────────────────

class _MeasurementList extends StatelessWidget {
  final List<MeasurementRecord> measurements;
  const _MeasurementList({required this.measurements});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('จุดวัด (${measurements.length} จุด)',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textNormal)),
          ],
        ),
        const SizedBox(height: 12),
        ...measurements.asMap().entries.map((entry) {
          final m = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: entry.key < measurements.length - 1 ? 10 : 0),
            child: _MeasurementCard(record: m),
          );
        }),
      ],
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final MeasurementRecord record;
  const _MeasurementCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final date = record.measuredAt;
    final dateStr = date != null
        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : '-';

    final metrics = [
      ('pH', record.ph.toStringAsFixed(1), getSoilStatus('ph', record.ph)),
      ('N', record.nitrogen.toStringAsFixed(0), getSoilStatus('nitrogen', record.nitrogen)),
      ('P', record.phosphorus.toStringAsFixed(0), getSoilStatus('phosphorus', record.phosphorus)),
      ('K', record.potassium.toStringAsFixed(0), getSoilStatus('potassium', record.potassium)),
      ('ชื้น', '${record.moisture.toStringAsFixed(0)}%', getSoilStatus('moisture', record.moisture)),
      ('EC', record.ec.toStringAsFixed(1), getSoilStatus('ec', record.ec)),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                record.pointName ?? 'จุดที่ ${record.id?.substring(0, 6) ?? ""}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textNormal,
                ),
              ),
              Text(dateStr,
                  style: TextStyle(fontSize: 11, color: context.colors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: metrics.map((m) {
              final (label, val, status) = m;
              Color bg;
              Color text;
              switch (status) {
                case SoilStatus.low:
                  bg = isDark ? const Color(0xFF1e3a5f) : const Color(0xFFdbeafe);
                  text = isDark ? const Color(0xFF93c5fd) : const Color(0xFF1d4ed8);
                  break;
                case SoilStatus.high:
                  bg = isDark ? const Color(0xFF450a0a) : const Color(0xFFfee2e2);
                  text = isDark ? const Color(0xFFfca5a5) : const Color(0xFFb91c1c);
                  break;
                case SoilStatus.normal:
                  bg = isDark ? const Color(0xFF052e16) : const Color(0xFFdcfce7);
                  text = isDark ? const Color(0xFF86efac) : const Color(0xFF15803d);
                  break;
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$label ', style: TextStyle(fontSize: 11, color: text.withValues(alpha: 0.7))),
                    Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: text)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Cassava Rank Card ────────────────────────────────────────────────────────

class _CassavaCard extends StatelessWidget {
  final PlantSuitability suitability;
  final int rank;
  final CassavaVariety? variety;
  final PlotRecord plot;

  const _CassavaCard({
    required this.suitability,
    required this.rank,
    this.variety,
    required this.plot,
  });

  @override
  Widget build(BuildContext context) {

    final Color scoreColor = suitability.scorePercent >= 80
        ? Colors.green.shade600
        : (suitability.scorePercent >= 50 ? Colors.orange.shade600 : Colors.red.shade600);

    final String rankEmoji = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#$rank',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(rankEmoji, style: TextStyle(fontSize: rank <= 3 ? 18 : 14, fontWeight: FontWeight.w700, color: scoreColor)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(suitability.plantName,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: context.colors.textNormal)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: scoreColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${suitability.scorePercent.toStringAsFixed(0)}%',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: scoreColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (variety != null)
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 4),
              child: Text(variety!.description,
                  style: TextStyle(
                      fontSize: 12,
                      color: context.colors.textMuted,
                      height: 1.4)),
            ),

          // ── Variety info chips ──
          if (variety != null)
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 8),
              child: Text(
                'ทนแล้ง: ${variety!.droughtTolerance}  •  ผลผลิต: ${variety!.yieldPotential}  •  แป้ง: ${variety!.starchRange}',
                style: TextStyle(fontSize: 11, color: context.colors.textMuted),
              ),
            ),

          // ── Score bar ──
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: suitability.scorePercent / 100,
                minHeight: 4,
                backgroundColor: context.colors.borderColor,
                valueColor: AlwaysStoppedAnimation(scoreColor),
              ),
            ),
          ),

          // ── Fertilizer hint ──
          if (variety != null)
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 12),
              child: Text(
                'ปุ๋ยรองพื้น: ${variety!.baseFertCode} (${variety!.baseFertRate})',
                style: TextStyle(fontSize: 12, color: context.colors.textNormal),
              ),
            ),

          // ── Issues ──
          if (suitability.recommendations.isNotEmpty &&
              !suitability.recommendations.containsKey('general'))
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ข้อควรระวัง',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textNormal)),
                  const SizedBox(height: 4),
                  ...suitability.recommendations.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('• ${e.value}',
                        style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textMuted,
                            height: 1.4)),
                  )),
                ],
              ),
            ),

          // ── View Fertilizer Plan Button ──
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => context.push('/cassava-fertilizer', extra: {
                  'plot': plot,
                  'varietyId': suitability.plantId,
                }),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.primaryBtn,
                  side: BorderSide(color: context.colors.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'ดูแผนปุ๋ย',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Sheet: All Varieties ──────────────────────────────────────────────

class _AllVarietiesSheet extends StatefulWidget {
  final PlotRecord plot;

  const _AllVarietiesSheet({required this.plot});

  @override
  State<_AllVarietiesSheet> createState() => _AllVarietiesSheetState();
}

class _AllVarietiesSheetState extends State<_AllVarietiesSheet> {
  List<PlantSuitability>? _all;
  List<PlantSuitability>? _filtered;
  int _displayCount = 10;
  bool _isLoadingMore = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (_all != null) {
      setState(() {
        _filtered = _all!.where((s) => s.plantName.toLowerCase().contains(query)).toList();
        _displayCount = 10;
      });
    }
  }

  Future<void> _loadData() async {
    // Construct a lightweight SensorData to pass to compute isolate
    final sensorData = SensorData(
      ph: widget.plot.ph,
      nitrogen: widget.plot.nitrogen,
      phosphorus: widget.plot.phosphorus,
      potassium: widget.plot.potassium,
      moisture: widget.plot.moisture,
      temperature: widget.plot.temperature,
      ec: widget.plot.ec,
      salinity: widget.plot.salinity,
    );
    
    // Evaluate in background isolate to prevent UI jank
    final results = await compute(evaluateAllSuitability, sensorData);
    
    if (mounted) {
      setState(() {
        _all = results;
        _filtered = results;
      });
    }
  }

  void _loadMore() async {
    if (_isLoadingMore || _filtered == null || _displayCount >= _filtered!.length) return;
    setState(() {
      _isLoadingMore = true;
    });
    
    // Fake network delay to simulate feed loading
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _displayCount = (_displayCount + 10).clamp(0, _filtered!.length);
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1f2937) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('เปรียบเทียบสายพันธุ์ทั้งหมด',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: context.colors.textNormal)),
                        Text('เรียงตามความเหมาะสมกับดินของแปลงคุณ',
                            style: TextStyle(
                                fontSize: 12, color: context.colors.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: context.colors.textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: context.colors.textNormal, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'ค้นหาสายพันธุ์...',
                  hintStyle: TextStyle(color: context.colors.textMuted),
                  prefixIcon: Icon(Icons.search, color: context.colors.textMuted, size: 20),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // List
            Expanded(
              child: _filtered == null
                  ? Center(
                      child: CircularProgressIndicator(
                        color: context.colors.primaryBtn,
                      ),
                    )
                  : _filtered!.isEmpty
                      ? Center(
                          child: Text(
                            'ไม่พบสายพันธุ์ที่ค้นหา',
                            style: TextStyle(color: context.colors.textMuted),
                          ),
                        )
                      : NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification scrollInfo) {
                            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                              _loadMore();
                            }
                            return false;
                          },
                          child: ListView.separated(
                            controller: controller,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _displayCount < _filtered!.length ? _displayCount + 1 : _filtered!.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, index) {
                              if (index == _displayCount) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24, height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: context.colors.primaryBtn),
                                    ),
                                  ),
                                );
                              }

                              final s = _filtered![index];
                              final rank = _all!.indexOf(s) + 1;
                  final variety = cassavaVarieties[s.plantId];
                  final scoreColor = s.scorePercent >= 80
                      ? Colors.green.shade600
                      : s.scorePercent >= 50
                          ? Colors.orange.shade600
                          : Colors.red.shade600;

                  final String rankEmoji = switch (rank) {
                    1 => '🥇',
                    2 => '🥈',
                    3 => '🥉',
                    _ => '#$rank',
                  };

                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/cassava-fertilizer', extra: {
                        'plot': widget.plot,
                        'varietyId': s.plantId,
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.colors.borderColor.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          // Rank number
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: scoreColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                rankEmoji,
                                style: TextStyle(
                                  fontSize: rank <= 3 ? 18 : 14,
                                  fontWeight: FontWeight.w700,
                                  color: scoreColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Name + description
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.plantName,
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: context.colors.textNormal)),
                                if (variety != null) ...[
                                  Text(
                                    'แป้ง ${variety.starchRange}  •  ทนแล้ง: ${variety.droughtTolerance}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: context.colors.textMuted),
                                  ),
                                  const SizedBox(height: 4),
                                  // Score bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: s.scorePercent / 100,
                                      minHeight: 2,
                                      backgroundColor:
                                          context.colors.borderColor,
                                      valueColor: AlwaysStoppedAnimation(
                                          scoreColor),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Score badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: scoreColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${s.scorePercent.toStringAsFixed(0)}%',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: scoreColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: context.colors.textMuted.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }
}
