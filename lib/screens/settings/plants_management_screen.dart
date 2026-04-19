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
            content: Text('ไม่สามารถลบได้: มีประวัติการใช้พืชชนิดนี้อยู่', style: TextStyle(color: context.colors.errorText)),
            backgroundColor: context.colors.errorBg,
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
        title: Text('ยืนยันการลบ', style: TextStyle(color: context.colors.textNormal, fontWeight: FontWeight.bold)),
        content: Text('คุณต้องการลบ "$name" ใช่หรือไม่?\n\n*ระบบไม่อนุญาตให้ลบหากมีประวัติการบันทึกข้อมูลด้วยพืชชนิดนี้แล้ว', 
            style: TextStyle(color: context.colors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ยกเลิก', style: TextStyle(color: context.colors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.colors.errorText),
            child: const Text('ลบ', style: TextStyle(fontWeight: FontWeight.bold)),
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
        title: Text('เพิ่มชนิดพืช', style: TextStyle(color: context.colors.textNormal, fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: context.colors.textNormal),
          decoration: InputDecoration(
            hintText: 'เช่น มะม่วง, ทุเรียน, etc.',
            hintStyle: TextStyle(color: context.colors.textMuted.withValues(alpha: 0.5)),
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: TextStyle(color: context.colors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: context.colors.primaryBtn),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('จัดการชนิดพืช', style: TextStyle(color: context.colors.textNormal, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: context.colors.textNormal, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: context.colors.primaryBtn))
        : ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _plants.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final plant = _plants[index];

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.colors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.borderColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.eco, 
                        color: context.colors.primaryBtn, 
                        size: 20
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        plant['name'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: context.colors.textNormal,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _confirmDelete(plant),
                      icon: const Icon(Icons.delete_outline),
                      color: context.colors.errorText,
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPlantDialog,
        backgroundColor: context.colors.primaryBtn,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มพืชใหม่', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
