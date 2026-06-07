import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

class PlantsManagementScreen extends StatefulWidget {
  const PlantsManagementScreen({super.key});

  @override
  State<PlantsManagementScreen> createState() => _PlantsManagementScreenState();
}

class _PlantsManagementScreenState extends State<PlantsManagementScreen> {
  List<Map<String, dynamic>> _plants = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final plants = await ApiService.getPlants();
      if (mounted) setState(() { _plants = plants; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _deletePlant(Map<String, dynamic> plant) async {
    final id = plant['id'].toString();
    final name = plant['name'] as String;

    try {
      await ApiService.deletePlant(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบ "$name" เรียบร้อยแล้ว', style: const TextStyle(color: Colors.white)),
            backgroundColor: context.colors.primaryBtn,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadPlants();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ไม่สามารถลบได้: มีประวัติการใช้พืชชนิดนี้อยู่', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> plant) async {
    final name = plant['name'] as String;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actionsAlignment: MainAxisAlignment.end,
        title: Text('ยืนยันการลบ', style: TextStyle(color: context.colors.textNormal, fontWeight: FontWeight.bold)),
        content: Text(
          'คุณต้องการลบ "$name" ใช่หรือไม่?\n\n*ระบบไม่อนุญาตให้ลบหากมีประวัติการบันทึกข้อมูลด้วยพืชชนิดนี้แล้ว',
          style: TextStyle(color: context.colors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('ยกเลิก', style: TextStyle(color: context.colors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text('ลบ', style: TextStyle(color: Colors.red.shade500, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deletePlant(plant);
    }
  }

  Future<void> _showAddPlantPage() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _AddPlantPage(),
      ),
    );

    if (result != null && mounted) {
      try {
        await ApiService.addPlant(
          result['name'],
          minPh: result['min_ph'],
          maxPh: result['max_ph'],
          minN: result['min_n'],
          maxN: result['max_n'],
          minP: result['min_p'],
          maxP: result['max_p'],
          minK: result['min_k'],
          maxK: result['max_k'],
        );
        await _loadPlants();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เพิ่มพืชไม่สำเร็จ: $e', style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        title: Text('จัดการชนิดพืช', style: TextStyle(color: c.textNormal, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textNormal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(c),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPlantPage,
        backgroundColor: c.primaryBtn,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('เพิ่มพืชใหม่', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildBody(AppColors c) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: c.primaryBtn));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: c.textMuted),
              const SizedBox(height: 16),
              Text('ไม่สามารถโหลดข้อมูลได้', style: TextStyle(color: c.textNormal, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: c.textMuted, fontSize: 13)),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _loadPlants,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('ลองใหม่'),
                style: TextButton.styleFrom(foregroundColor: c.primaryBtn),
              ),
            ],
          ),
        ),
      );
    }

    if (_plants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco_outlined, size: 48, color: c.textMuted),
              const SizedBox(height: 16),
              Text('ไม่มีข้อมูลชนิดพืช', style: TextStyle(color: c.textNormal, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('กรุณาเพิ่มชนิดพืชใหม่', style: TextStyle(color: c.textMuted)),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: c.primaryBtn,
      onRefresh: _loadPlants,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        itemCount: 1,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.borderColor),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              for (int i = 0; i < _plants.length; i++) ...[
                _PlantItem(
                  plant: _plants[i],
                  onDelete: () => _confirmDelete(_plants[i]),
                ),
                if (i < _plants.length - 1)
                  Divider(height: 1, indent: 54, endIndent: 0, color: c.dividerColor.withValues(alpha: 0.6)),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Plant list item ──────────────────────────────────────────────────────────

class _PlantItem extends StatelessWidget {
  final Map<String, dynamic> plant;
  final VoidCallback onDelete;

  const _PlantItem({required this.plant, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasDetails = plant['min_ph'] != null || plant['min_n'] != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.grass_rounded, size: 22, color: c.textNormal),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant['name'] as String,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.textNormal),
                ),
                if (hasDetails) ...[
                  const SizedBox(height: 4),
                  Text(
                    'pH: ${plant['min_ph'] ?? '-'} ถึง ${plant['max_ph'] ?? '-'}',
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                  ),
                  if (plant['min_n'] != null || plant['max_n'] != null)
                    Text(
                      'N: ${plant['min_n'] ?? '-'}–${plant['max_n'] ?? '-'}  P: ${plant['min_p'] ?? '-'}–${plant['max_p'] ?? '-'}  K: ${plant['min_k'] ?? '-'}–${plant['max_k'] ?? '-'} mg/kg',
                      style: TextStyle(fontSize: 12, color: c.textMuted),
                    ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            color: Colors.red.shade400,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─── Add plant page (full-screen dialog — avoids bottom sheet perf issues) ────

class _AddPlantPage extends StatefulWidget {
  const _AddPlantPage();

  @override
  State<_AddPlantPage> createState() => _AddPlantPageState();
}

class _AddPlantPageState extends State<_AddPlantPage> {
  final _nameCtrl = TextEditingController();
  final _minPhCtrl = TextEditingController();
  final _maxPhCtrl = TextEditingController();
  final _minNCtrl = TextEditingController();
  final _maxNCtrl = TextEditingController();
  final _minPCtrl = TextEditingController();
  final _maxPCtrl = TextEditingController();
  final _minKCtrl = TextEditingController();
  final _maxKCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _minPhCtrl.dispose();
    _maxPhCtrl.dispose();
    _minNCtrl.dispose();
    _maxNCtrl.dispose();
    _minPCtrl.dispose();
    _maxPCtrl.dispose();
    _minKCtrl.dispose();
    _maxKCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, {
      'name': name,
      'min_ph': double.tryParse(_minPhCtrl.text),
      'max_ph': double.tryParse(_maxPhCtrl.text),
      'min_n': double.tryParse(_minNCtrl.text),
      'max_n': double.tryParse(_maxNCtrl.text),
      'min_p': double.tryParse(_minPCtrl.text),
      'max_p': double.tryParse(_maxPCtrl.text),
      'min_k': double.tryParse(_minKCtrl.text),
      'max_k': double.tryParse(_maxKCtrl.text),
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('เพิ่มชนิดพืช', style: TextStyle(color: c.textNormal, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: c.textNormal),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _submit,
              style: TextButton.styleFrom(
                backgroundColor: c.primaryBtn,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text('บันทึก', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        children: [
          // ─ Plant name
          _label('ชื่อพืช', c),
          const SizedBox(height: 8),
          _textField(_nameCtrl, 'เช่น มะม่วง, ทุเรียน', c),
          const SizedBox(height: 24),

          // ─ pH range
          _label('ค่า pH ที่เหมาะสม', c),
          const SizedBox(height: 8),
          _rangeRow(null, _minPhCtrl, _maxPhCtrl, c),
          const SizedBox(height: 24),

          // ─ NPK section
          Text('ช่วง N-P-K ที่เหมาะสม (mg/kg)', style: TextStyle(color: c.textNormal, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('กรอกช่วงค่าที่พืชต้องการ (ต่ำสุด–สูงสุด)', style: TextStyle(color: c.textMuted, fontSize: 11)),
          const SizedBox(height: 12),
          _rangeRow('N', _minNCtrl, _maxNCtrl, c),
          const SizedBox(height: 10),
          _rangeRow('P', _minPCtrl, _maxPCtrl, c),
          const SizedBox(height: 10),
          _rangeRow('K', _minKCtrl, _maxKCtrl, c),
        ],
      ),
    );
  }

  Widget _label(String text, AppColors c) =>
      Text(text, style: TextStyle(color: c.textNormal, fontSize: 14));

  Widget _textField(TextEditingController ctrl, String hint, AppColors c) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: c.textNormal),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textMuted.withValues(alpha: 0.5)),
        filled: true,
        fillColor: c.bgAlt,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _rangeRow(String? label, TextEditingController minCtrl, TextEditingController maxCtrl, AppColors c) {
    return Row(
      children: [
        if (label != null) SizedBox(width: 28, child: Text(label, style: TextStyle(color: c.primaryBtn, fontWeight: FontWeight.w700, fontSize: 13))),
        Expanded(child: _numField(minCtrl, 'ต่ำสุด', c)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('–', style: TextStyle(color: c.textMuted))),
        Expanded(child: _numField(maxCtrl, 'สูงสุด', c)),
      ],
    );
  }

  Widget _numField(TextEditingController ctrl, String hint, AppColors c) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: c.textNormal, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textMuted.withValues(alpha: 0.5), fontSize: 12),
        filled: true,
        fillColor: c.bgAlt,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}

