import 'package:flutter/material.dart';
import '../../services/database_service.dart';
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
    final plants = await DatabaseService.getPlants();
    if (mounted) {
      setState(() {
        _plants = plants;
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePlant(Map<String, dynamic> plant) async {
    final id = plant['id'] as String;
    final name = plant['name'] as String;

    try {
      await DatabaseService.deletePlant(id);
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
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('เพิ่มชนิดพืช', style: TextStyle(color: context.colors.textNormal, fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: TextStyle(color: context.colors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primaryBtn,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await DatabaseService.addPlant(name);
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(Icons.grass_rounded, size: 22, color: context.colors.textNormal),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              plant['name'] as String,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: context.colors.textNormal,
              ),
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
