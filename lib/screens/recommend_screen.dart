import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../models/sensor_data.dart';
import '../models/calculations.dart';
import '../services/api_service.dart';
import '../providers/measurements_provider.dart';
import '../providers/plot_provider.dart';

class RecommendScreen extends StatefulWidget {
  final PlotRecord? plot;
  const RecommendScreen({super.key, this.plot});

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  PlotRecord? get plot => widget.plot;
  List<CassavaVariety> _varieties = [];
  bool _isLoadingPlants = true;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    final plants = await ApiService.getPlants();
    if (mounted) {
      setState(() {
        _varieties = plants.map((p) => CassavaVariety.fromJson(p)).toList();
        _isLoadingPlants = false;
      });
    }
  }

  void _showAllSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AllVarietiesSheet(plot: plot!, varieties: _varieties),
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actionsAlignment: MainAxisAlignment.end,
        title: Text('ยืนยันการลบ',
            style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textNormal)),
        content: Text(
          plot!.measurementCount > 0
              ? 'คุณต้องการลบ "${plot!.name}" และข้อมูลการวัดทั้งหมด ${plot!.measurementCount} จุดใช่หรือไม่?'
              : 'คุณต้องการลบ "${plot!.name}" ใช่หรือไม่?\n\n*แปลงนี้ไม่มีข้อมูลบันทึก',
          style: TextStyle(color: context.colors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('ยกเลิก', style: TextStyle(color: context.colors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('ลบ', style: TextStyle(color: Colors.red.shade500, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      context.read<MeasurementsProvider>().remove(plot!.id);
      context.read<PlotProvider>().loadAvailablePlots();
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPlants) {
      return Scaffold(
        backgroundColor: context.colors.scaffoldBg,
        body: Center(child: CircularProgressIndicator(color: context.colors.primaryBtn)),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (plot == null || plot!.measurements.isEmpty) {
      return Scaffold(
        backgroundColor: context.colors.scaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 20, color: context.colors.textNormal),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: context.colors.borderColor.withValues(alpha: isDark ? 0.2 : 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.grass_outlined, size: 64, color: context.colors.textMuted),
                ),
                const SizedBox(height: 24),
                Text('ไม่มีข้อมูลการวัดในแปลงนี้',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.colors.textNormal)),
                const SizedBox(height: 8),
                Text('กรุณาบันทึกค่าอย่างน้อย 1 จุดเพื่อดูผลวิเคราะห์ความเหมาะสมของสายพันธุ์',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: context.colors.textMuted, height: 1.5)),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.errorText,
                    side: BorderSide(color: context.colors.errorBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  label: const Text('ลบแปลงนี้', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final top3 = evaluateSuitability(plot!, _varieties);

    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            backgroundColor: context.colors.scaffoldBg,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 20, color: context.colors.textNormal),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                onPressed: _confirmDelete,
                icon: Icon(Icons.delete_outline_rounded, size: 22, color: context.colors.errorText),
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                
                // ── Hero Section ──
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: context.colors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.colors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.colors.bgAlt,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ผลวิเคราะห์แปลง',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.colors.textNormal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        plot!.name,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: context.colors.textNormal,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.format_list_numbered_rounded, size: 14, color: context.colors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            'จำนวน ${plot!.measurementCount} จุดวัด',
                            style: TextStyle(fontSize: 14, color: context.colors.textMuted, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Action Buttons Row ──
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.history_rounded,
                        title: 'ประวัติค่าดิน',
                        subtitle: 'จัดการจุดวัด',
                        color: context.colors.primaryBtn,
                        onTap: () {
                          context.push('/plot-measurements', extra: {'plot': plot}).then((_) {
                            if (mounted) setState(() {});
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.eco_rounded,
                        title: 'สายพันธุ์',
                        subtitle: 'เปรียบเทียบทั้งหมด',
                        color: context.colors.primaryBtn,
                        onTap: () => _showAllSheet(context),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 36),

                // ── Section title ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('3 อันดับแรก',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: context.colors.textNormal,
                            letterSpacing: -0.5)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('เหมาะสมกับดินของคุณที่สุด',
                          style: TextStyle(fontSize: 13, color: context.colors.textMuted, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Top 3 Cassava cards ──
                ...top3.asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final s = entry.value;
                  final variety = _varieties.firstWhere((v) => v.id == s.plantId);
                  return _CassavaCard(
                    suitability: s, 
                    rank: rank, 
                    variety: variety, 
                    plot: plot!
                  );
                }),

              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.colors.textNormal),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: context.colors.textMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CassavaCard extends StatelessWidget {
  final PlantSuitability suitability;
  final int rank;
  final CassavaVariety variety;
  final PlotRecord plot;

  const _CassavaCard({
    required this.suitability,
    required this.rank,
    required this.variety,
    required this.plot,
  });

  @override
  Widget build(BuildContext context) {
    final Color scoreColor = suitability.scorePercent >= 80
        ? context.colors.primaryBtn
        : (suitability.scorePercent >= 50 ? context.colors.warningOrange : context.colors.errorText);

    final Color rankColor = switch (rank) { 1 => context.colors.primaryBtn, 2 => context.colors.warningOrange, _ => context.colors.textMuted };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(color: rankColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Center(child: Text('$rank', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: rankColor))),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  suitability.plantName,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.textNormal),
                ),
              ),
              Text(
                '${suitability.scorePercent.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: scoreColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(variety.description,
              style: TextStyle(fontSize: 13, color: context.colors.textMuted, height: 1.5)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _TraitItem(icon: Icons.water_drop_outlined, label: 'ทนแล้ง', value: variety.droughtTolerance),
              _TraitItem(icon: Icons.scale_rounded, label: 'ผลผลิต', value: variety.yieldPotential),
              _TraitItem(icon: Icons.pie_chart_outline_rounded, label: 'แป้ง', value: variety.starchRange),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'ปุ๋ยรองพื้น: ${variety.baseFertCode} (${variety.baseFertRate})',
                  style: TextStyle(fontSize: 13, color: context.colors.textMuted),
                ),
              ),
              FilledButton(
                onPressed: () => context.push('/cassava-fertilizer', extra: {
                  'plot': plot,
                  'variety': variety,
                }),
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.primaryBtn,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('ดูแผนปุ๋ย', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (suitability.recommendations.isNotEmpty &&
              !suitability.recommendations.containsKey('general')) ...[
            const SizedBox(height: 8),
            Divider(height: 1, color: context.colors.dividerColor.withValues(alpha: 0.6)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: context.colors.warningOrange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    suitability.recommendations.entries.map((e) => e.value).join('\n'),
                    style: TextStyle(fontSize: 12, color: context.colors.warningText, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}



class _TraitItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TraitItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.colors.textMuted),
        const SizedBox(width: 4),
        Text('$label: ', style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.textNormal)),
      ],
    );
  }
}

// ─── Bottom Sheet: All Varieties ──────────────────────────────────────────────

class _AllVarietiesSheet extends StatefulWidget {
  final PlotRecord plot;
  final List<CassavaVariety> varieties;

  const _AllVarietiesSheet({required this.plot, required this.varieties});

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
    // Evaluate directly
    final results = evaluateAllSuitability(sensorData, widget.varieties);
    
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
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: context.colors.cardBg,
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
                  color: context.colors.textMuted.withValues(alpha: 0.3),
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
                  fillColor: context.colors.bgAlt,
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
                  final variety = widget.varieties.firstWhere((v) => v.id == s.plantId);
                  final scoreColor = s.scorePercent >= 80
                      ? context.colors.primaryBtn
                      : s.scorePercent >= 50
                          ? context.colors.warningOrange
                          : context.colors.errorText;

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
                        'variety': variety,
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
                              color: context.colors.bgAlt,
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
