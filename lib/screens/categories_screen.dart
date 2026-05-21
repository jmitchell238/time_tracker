import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/entry_category.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<AppProvider>().categories;

    return Scaffold(
      backgroundColor: AppColors.of(context).bgDeep,
      body: Column(
        children: [
          Container(
            color: AppColors.of(context).bgDeep,
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 12,
              16,
              12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back, size: 18, color: AppColors.of(context).fg),
                      const SizedBox(width: 4),
                      Text('Back',
                          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.of(context).fg)),
                    ],
                  ),
                ),
                Text('Categories',
                    style: GoogleFonts.lora(
                        fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
                GestureDetector(
                  onTap: () => _showCategorySheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('+ Add',
                        style: GoogleFonts.dmSans(
                            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: cats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.label_outline, size: 48, color: AppColors.of(context).fg3),
                        const SizedBox(height: 12),
                        Text('No categories yet',
                            style: GoogleFonts.dmSans(
                                fontSize: 15, color: AppColors.of(context).fg2)),
                        const SizedBox(height: 6),
                        Text('Tap + Add to create one',
                            style: GoogleFonts.dmSans(
                                fontSize: 13, color: AppColors.of(context).fg3)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: cats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _CategoryTile(category: cats[i]),
                  ),
          ),
        ],
      ),
    );
  }

  void _showCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategorySheet(category: null),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final EntryCategory category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.of(context).bgBase,
        border: Border.all(color: AppColors.of(context).border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: category.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(category.name,
                style: GoogleFonts.dmSans(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.of(context).fg)),
          ),
          GestureDetector(
            onTap: () => _showEdit(context),
            child: Icon(Icons.edit_outlined, size: 18, color: AppColors.of(context).fg3),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _confirmDelete(context),
            child: Icon(Icons.delete_outline, size: 18, color: AppColors.of(context).fg3),
          ),
        ],
      ),
    );
  }

  void _showEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategorySheet(category: category),
    );
  }

  void _confirmDelete(BuildContext context) {
    final provider = context.read<AppProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).bgBase,
        title: Text('Delete Category',
            style: GoogleFonts.lora(color: AppColors.of(context).fg)),
        content: Text(
            'Delete "${category.name}"? Jobs using this category will become uncategorized.',
            style: GoogleFonts.dmSans(color: AppColors.of(context).fg2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: AppColors.of(context).fg2)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteCategory(category.id);
              Navigator.pop(ctx);
            },
            child: Text('Delete', style: GoogleFonts.dmSans(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CategorySheet extends StatefulWidget {
  final EntryCategory? category;
  const _CategorySheet({required this.category});

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  late TextEditingController _nameCtrl;
  late int _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name ?? '');
    _selectedColor = widget.category?.colorValue ?? EntryCategory.palette.first.value;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.of(context).bgBase,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.of(context).border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(isEdit ? 'Edit Category' : 'New Category',
                style: GoogleFonts.lora(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              style: GoogleFonts.dmSans(color: AppColors.of(context).fg),
              decoration: InputDecoration(
                labelText: 'Category name',
                labelStyle: GoogleFonts.dmSans(color: AppColors.of(context).fg3),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.of(context).border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.accent),
                ),
                filled: true,
                fillColor: AppColors.of(context).bgDeep,
              ),
            ),
            const SizedBox(height: 16),
            Text('Color',
                style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.of(context).fg2)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: EntryCategory.palette.map((color) {
                final isSelected = _selectedColor == color.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color.value),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(isEdit ? 'Save Changes' : 'Create Category',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final provider = context.read<AppProvider>();
    if (widget.category == null) {
      provider.addCategory(name, _selectedColor);
    } else {
      provider.updateCategory(widget.category!.id, name: name, colorValue: _selectedColor);
    }
    Navigator.pop(context);
  }
}
