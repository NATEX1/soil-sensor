import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/sensor_data.dart';
import '../models/calculations.dart';
import '../theme/app_colors.dart';

class CassavaFertilizerScreen extends StatelessWidget {
  final PlotRecord plot;
  final CassavaVariety variety;

  const CassavaFertilizerScreen({
    super.key,
    required this.plot,
    required this.variety,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 32),
        children: [
          // ── Header ──
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.arrow_back_ios_new,
                    size: 20, color: context.colors.textNormal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('แผนการใส่ปุ๋ย',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: context.colors.textNormal,
                            letterSpacing: -0.5)),
                    Text('${variety.name}  •  ${variety.shortCode}',
                        style: TextStyle(
                            fontSize: 13, color: context.colors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Variety summary chip row ──
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(context, Icons.water_drop_outlined,
                  'ทนแล้ง: ${variety.droughtTolerance}', Colors.blue.shade600),
              _chip(context, Icons.trending_up_rounded,
                  'ผลผลิต: ${variety.yieldPotential}', Colors.green.shade600),
              _chip(context, Icons.grain_rounded,
                  'แป้ง: ${variety.starchRange}', Colors.orange.shade600),
            ],
          ),
          const SizedBox(height: 20),

          // ── Soil vs Variety requirement ──
          _SectionTitle(context: context, title: 'สภาพดินปัจจุบัน vs ความต้องการ'),
          const SizedBox(height: 10),
          _SoilRequirementCard(plot: plot, variety: variety),
          const SizedBox(height: 20),

          // ── Fertilizer plan ──
          _SectionTitle(context: context, title: 'แผนการใส่ปุ๋ยตามช่วงเวลา'),
          const SizedBox(height: 10),
          _FertPlanTimeline(plot: plot, variety: variety),
          const SizedBox(height: 20),

          // ── Notes ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 18, color: Colors.amber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'อัตราปุ๋ยที่แนะนำเป็นค่าทั่วไป ควรปรับตามผลวิเคราะห์ดินจริงและสภาพแปลง '
                    'แนะนำให้ตรวจวัดดินซ้ำทุก 3-6 เดือนเพื่อผลลัพธ์ที่ดีที่สุด',
                    style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textMuted,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
      BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08), // Reduced opacity
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)), // Lighter border
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ─── Section Title ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final BuildContext context;
  final String title;
  const _SectionTitle({required this.context, required this.title});

  @override
  Widget build(BuildContext ctx) {
    return Row(
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.colors.textNormal)),
      ],
    );
  }
}

// ─── Soil vs Requirement Card ─────────────────────────────────────────────────

class _SoilRequirementCard extends StatelessWidget {
  final PlotRecord plot;
  final CassavaVariety variety;
  const _SoilRequirementCard({required this.plot, required this.variety});

  @override
  Widget build(BuildContext context) {
    final rows = [
      _ReqRow(
        label: 'pH',
        current: plot.ph.toStringAsFixed(1),
        required: '${variety.minPh}–${variety.maxPh}',
        ok: plot.ph >= variety.minPh && plot.ph <= variety.maxPh,
        low: plot.ph < variety.minPh,
      ),
      _ReqRow(
        label: 'N (mg/kg)',
        current: plot.nitrogen.toStringAsFixed(0),
        required: '≥ ${variety.minN.toStringAsFixed(0)}',
        ok: plot.nitrogen >= variety.minN,
        low: plot.nitrogen < variety.minN,
      ),
      _ReqRow(
        label: 'P (mg/kg)',
        current: plot.phosphorus.toStringAsFixed(0),
        required: '≥ ${variety.minP.toStringAsFixed(0)}',
        ok: plot.phosphorus >= variety.minP,
        low: plot.phosphorus < variety.minP,
      ),
      _ReqRow(
        label: 'K (mg/kg)',
        current: plot.potassium.toStringAsFixed(0),
        required: '≥ ${variety.minK.toStringAsFixed(0)}',
        ok: plot.potassium >= variety.minK,
        low: plot.potassium < variety.minK,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.borderColor, width: 0.5), // Minimal border
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          final row = e.value;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(row.label,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textMuted)),
                    ),
                    Expanded(
                      child: Text(row.current,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: context.colors.textNormal)),
                    ),
                    Text('ต้องการ ${row.required}',
                        style: TextStyle(
                            fontSize: 11, color: context.colors.textMuted)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: row.ok
                            ? Colors.green.withValues(alpha: 0.08)
                            : Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        row.ok ? 'ผ่าน' : (row.low ? 'ต่ำ' : 'สูง'),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: row.ok
                                ? Colors.green.shade600
                                : Colors.orange.shade600),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, color: context.colors.borderColor),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ReqRow {
  final String label, current, required;
  final bool ok, low;
  const _ReqRow({
    required this.label,
    required this.current,
    required this.required,
    required this.ok,
    required this.low,
  });
}

// ─── Fertilizer Timeline ──────────────────────────────────────────────────────

class _FertPlanTimeline extends StatelessWidget {
  final PlotRecord plot;
  final CassavaVariety variety;
  const _FertPlanTimeline({required this.plot, required this.variety});

  @override
  Widget build(BuildContext context) {
    final needsPh = plot.ph < variety.minPh || plot.ph > variety.maxPh;
    final needsN = plot.nitrogen < variety.minN;
    final needsP = plot.phosphorus < variety.minP;
    final needsK = plot.potassium < variety.minK;

    final steps = <_FertStep>[
      // Step 0: Soil prep (if needed)
      if (needsPh)
        _FertStep(
          icon: '🪨',
          title: 'เตรียมดิน (ก่อนปลูก 2–4 สัปดาห์)',
          color: Colors.purple.shade600,
          items: [
            if (plot.ph < variety.minPh)
              _FertItem(
                code: 'ปูนขาว (CaCO₃)',
                purpose: 'ปรับ pH ให้อยู่ในช่วง ${variety.minPh}–${variety.maxPh}',
                rate: '200–500 กก./ไร่ ไถกลบก่อนปลูก',
              ),
            if (plot.ph > variety.maxPh)
              const _FertItem(
                code: 'กำมะถันบด (S) หรือ 21-0-0',
                purpose: 'ลด pH ให้อยู่ในช่วงที่เหมาะสม',
                rate: 'กำมะถัน 50–100 กก./ไร่',
              ),
          ],
        ),

      // Step 1: Planting
      _FertStep(
        icon: '🌱',
        title: 'ตอนปลูก',
        color: Colors.green.shade600,
        items: [
          _FertItem(
            code: variety.baseFertCode,
            purpose: 'ปุ๋ยรองพื้น (${variety.baseFertName}) — ให้ N P K พื้นฐาน',
            rate: variety.baseFertRate,
          ),
          if (needsP)
            const _FertItem(
              code: 'DAP 18-46-0',
              purpose: 'เสริมฟอสฟอรัส สำหรับพัฒนาราก',
              rate: '20–30 กก./ไร่ ใส่รองก้นหลุม',
            ),
        ],
      ),

      // Step 2: 1–2 months
      _FertStep(
        icon: '🌿',
        title: 'อายุ 1–2 เดือน',
        color: Colors.teal.shade600,
        items: [
          if (needsN)
            const _FertItem(
              code: 'ยูเรีย 46-0-0',
              purpose: 'กระตุ้นการเจริญเติบโตของลำต้นและใบ',
              rate: '25–30 กก./ไร่',
            )
          else
            const _FertItem(
              code: 'ไม่จำเป็นต้องใส่ N เพิ่ม',
              purpose: 'ค่าไนโตรเจนในดินเพียงพอแล้ว',
              rate: 'ตรวจสอบการเจริญเติบโตของต้น',
            ),
        ],
      ),

      // Step 3: 3–4 months (top dress)
      _FertStep(
        icon: '🍀',
        title: 'อายุ 3–4 เดือน',
        color: Colors.orange.shade600,
        items: [
          _FertItem(
            code: variety.topFertCode,
            purpose: 'ปุ๋ยแต่งหน้า (${variety.topFertName}) — บำรุงหัวและเพิ่มแป้ง',
            rate: variety.topFertRate,
          ),
          if (needsK)
            const _FertItem(
              code: 'KCl 0-0-60',
              purpose: 'เสริมโพแทสเซียม เพิ่มคุณภาพและน้ำหนักหัว',
              rate: '25–30 กก./ไร่',
            ),
        ],
      ),
    ];

    return Column(
      children: steps.asMap().entries.map((e) {
        final isLast = e.key == steps.length - 1;
        return _TimelineStepCard(step: e.value, isLast: isLast);
      }).toList(),
    );
  }
}

class _FertStep {
  final String icon, title;
  final Color color;
  final List<_FertItem> items;
  const _FertStep({
    required this.icon,
    required this.title,
    required this.color,
    required this.items,
  });
}

class _FertItem {
  final String code, purpose, rate;
  const _FertItem({
    required this.code,
    required this.purpose,
    required this.rate,
  });
}

class _TimelineStepCard extends StatelessWidget {
  final _FertStep step;
  final bool isLast;
  const _TimelineStepCard({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: step.color.withValues(alpha: 0.08), // Softer background
                  shape: BoxShape.circle,
                  border: Border.all(color: step.color.withValues(alpha: 0.2)), // Softer border
                ),
                child: Center(
                  child: Text(step.icon, style: const TextStyle(fontSize: 16)),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: step.color.withValues(alpha: 0.15),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(step.title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: step.color)),
                ),
                const SizedBox(height: 8),
                ...step.items.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.colors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colors.borderColor, width: 0.5), // Minimal border
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.code,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700, // Reduced from w800
                                  color: step.color)),
                          const SizedBox(height: 3),
                          Text(item.purpose,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: context.colors.textMuted,
                                  height: 1.4)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.straighten,
                                  size: 13,
                                  color: context.colors.textMuted),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(item.rate,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: context.colors.textNormal)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
