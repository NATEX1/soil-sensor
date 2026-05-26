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

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    setState(() => _isLoading = true);
    final plants = await ApiService.getPlants();
    if (mounted) {
      setState(() {
        _plants = plants;
        _isLoading = false;
      });
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
      }
      _loadPlants();
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
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('ยืนยันการลบ', style: TextStyle(color: context.colors.textNormal, fontWeight: FontWeight.bold)),
        content: Text('คุณต้องการลบ "$name" ใช่หรือไม่?\n\n*ระบบไม่อนุญาตให้ลบหากมีประวัติการบันทึกข้อมูลด้วยพืชชนิดนี้แล้ว', 
            style: TextStyle(color: context.colors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ยกเลิก', style: TextStyle(color: context.colors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deletePlant(plant);
    }
  }

  Future<void> _showAddPlantDialog() async {
    final nameController = TextEditingController();
    final minPhController = TextEditingController();
    final maxPhController = TextEditingController();
    final minNController = TextEditingController();
    final maxNController = TextEditingController();
    final minPController = TextEditingController();
    final maxPController = TextEditingController();
    final minKController = TextEditingController();
    final maxKController = TextEditingController();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.colors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: context.colors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('เพิ่มชนิดพืช', style: TextStyle(color: context.colors.textNormal, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text('ชื่อพืช', style: TextStyle(color: context.colors.textNormal, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: TextStyle(color: context.colors.textNormal),
                decoration: InputDecoration(
                  hintText: 'เช่น มะม่วง, ทุเรียน, etc.',
                  hintStyle: TextStyle(color: context.colors.textMuted.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: context.colors.scaffoldBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              Text('ค่า pH ที่เหมาะสม', style: TextStyle(color: context.colors.textNormal, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minPhController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: context.colors.textNormal),
                      decoration: InputDecoration(
                        hintText: 'ต่ำสุด (เช่น 5.5)',
                        hintStyle: TextStyle(color: context.colors.textMuted.withValues(alpha: 0.5), fontSize: 12),
                        filled: true,
                        fillColor: context.colors.scaffoldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('-', style: TextStyle(color: context.colors.textNormal)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: maxPhController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: context.colors.textNormal),
                      decoration: InputDecoration(
                        hintText: 'สูงสุด (เช่น 7.0)',
                        hintStyle: TextStyle(color: context.colors.textMuted.withValues(alpha: 0.5), fontSize: 12),
                        filled: true,
                        fillColor: context.colors.scaffoldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('ช่วง N-P-K ที่เหมาะสม (mg/kg)', style: TextStyle(color: context.colors.textNormal, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('กรอกช่วงค่าที่พืชต้องการ (ต่ำสุด–สูงสุด) เพื่อให้ระบบตรวจสอบได้ทั้งสองด้าน',
                style: TextStyle(color: context.colors.textMuted, fontSize: 11)),
              const SizedBox(height: 10),
              // N row
              Row(
                children: [
                  SizedBox(width: 28, child: Text('N', style: TextStyle(color: context.colors.primaryBtn, fontWeight: FontWeight.w700, fontSize: 13))),
                  Expanded(
                    child: TextField(
                      controller: minNController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: context.colors.textNormal, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'ต่ำสุด',
                        hintStyle: TextStyle(color: context.colors.textMuted.withValues(alpha: 0.5), fontSize: 12),
                        filled: true, fillColor: context.colors.scaffoldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('–', style: TextStyle(color: context.colors.textMuted))),
                  Expanded(
                    child: TextField(
                      controller: maxNController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: context.colors.textNormal, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'สูงสุด',
                        hintStyle: TextStyle(color: context.colors.textMuted.withValues(alpha: 0.5), fontSize: 12),
                        filled: true, fillColor: context.colors.scaffoldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // P row
              Row(
                children: [
                  SizedBox(width: 28, child: Text('P', style: TextStyle(color: context.colors.primaryBtn, fontWeight: FontWeight.w700, fontSize: 13))),
                  Expanded(
                    child: TextField(
                      controller: minPController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: context.colors.textNormal, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'ต่ำสุด',
                        hintStyle: TextStyle(color: context.colors.textMuted.withValues(alpha: 0.5), fontSize: 12),
                        filled: true, fillColor: context.colors.scaffoldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('–', style: TextStyle(color: context.colors.textMuted))),
                  Expanded(
                    child: TextField(
                      controller: maxPController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: context.colors.textNormal, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'สูงสุด',
                        hintStyle: TextStyle(color: context.colors.textMuted.withValues(alpha: 0.5), fontSize: 12),
                        filled: true, fillColor: context.colors.scaffoldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // K row
              Row(
                children: [
                  SizedBox(width: 28, child: Text('K', style: TextStyle(color: context.colors.primaryBtn, fontWeight: FontWeight.w700, fontSize: 13))),
                  Expanded(
                    child: TextField(
                      controller: minKController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: context.colors.textNormal, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'ต่ำสุด',
                        hintStyle: TextStyle(color: context.colors.textMuted.withValues(alpha: 0.5), fontSize: 12),
                        filled: true, fillColor: context.colors.scaffoldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('–', style: TextStyle(color: context.colors.textMuted))),
                  Expanded(
                    child: TextField(
                      controller: maxKController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: context.colors.textNormal, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'สูงสุด',
                        hintStyle: TextStyle(color: context.colors.textMuted.withValues(alpha: 0.5), fontSize: 12),
                        filled: true, fillColor: context.colors.scaffoldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('ยกเลิก', style: TextStyle(color: context.colors.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) return;
                      Navigator.pop(context, {
                        'name': nameController.text.trim(),
                        'min_ph': double.tryParse(minPhController.text),
                        'max_ph': double.tryParse(maxPhController.text),
                        'min_n': double.tryParse(minNController.text),
                        'max_n': double.tryParse(maxNController.text),
                        'min_p': double.tryParse(minPController.text),
                        'max_p': double.tryParse(maxPController.text),
                        'min_k': double.tryParse(minKController.text),
                        'max_k': double.tryParse(maxKController.text),
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primaryBtn,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('บันทึก'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: AppBar(
        title: Text('จัดการชนิดพืช', style: TextStyle(color: context.colors.textNormal, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.textNormal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: context.colors.primaryBtn))
        : ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.all(20),
            children: [
              if (_plants.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text('ไม่มีข้อมูลชนิดพืช\nกรุณาเพิ่มชนิดพืชใหม่', 
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.colors.textMuted)),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: context.colors.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.colors.borderColor),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      for (int i = 0; i < _plants.length; i++) ...[
                        _buildPlantItem(_plants[i]),
                        if (i < _plants.length - 1)
                          Divider(
                            height: 1, 
                            indent: 54, // 16 padding + 22 icon + 16 spacing
                            endIndent: 0, 
                            color: context.colors.dividerColor.withValues(alpha: 0.6)
                          ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPlantDialog,
        backgroundColor: context.colors.primaryBtn,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('เพิ่มพืชใหม่', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildPlantItem(Map<String, dynamic> plant) {
    final hasDetails = plant['min_ph'] != null || plant['min_n'] != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.grass_rounded, size: 22, color: context.colors.textNormal),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant['name'] as String,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textNormal,
                  ),
                ),
                if (hasDetails) ...[
                  const SizedBox(height: 4),
                  Text(
                    'pH: ${plant['min_ph'] ?? '-'} ถึง ${plant['max_ph'] ?? '-'}',
                    style: TextStyle(fontSize: 12, color: context.colors.textMuted),
                  ),
                  if (plant['min_n'] != null || plant['max_n'] != null)
                    Text(
                      'N: ${plant['min_n'] ?? '-'}–${plant['max_n'] ?? '-'}  P: ${plant['min_p'] ?? '-'}–${plant['max_p'] ?? '-'}  K: ${plant['min_k'] ?? '-'}–${plant['max_k'] ?? '-'} mg/kg',
                      style: TextStyle(fontSize: 12, color: context.colors.textMuted),
                    ),
                ]
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(plant),
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
