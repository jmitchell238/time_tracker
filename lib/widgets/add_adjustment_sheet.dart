import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/time_entry.dart';
import '../providers/app_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import 'field_label.dart';

class AddAdjustmentSheet extends StatefulWidget {
  final TimeEntry entry;

  const AddAdjustmentSheet({super.key, required this.entry});

  static Future<void> show(BuildContext context, TimeEntry entry) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAdjustmentSheet(entry: entry),
    );
  }

  @override
  State<AddAdjustmentSheet> createState() => _AddAdjustmentSheetState();
}

class _AddAdjustmentSheetState extends State<AddAdjustmentSheet> {
  final _hoursCtrl = TextEditingController();
  bool _isAdding = true;

  @override
  void dispose() {
    _hoursCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final hours = double.tryParse(_hoursCtrl.text.trim()) ?? 0.0;
    if (hours == 0.0) return;
    final adjustment = _isAdding ? hours : -hours;
    Analytics.action('adjustment_applied', properties: {
      'hours': hours,
      'direction': _isAdding ? 'add' : 'subtract',
    });
    context.read<AppProvider>().addAdjustment(widget.entry.id, adjustment);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.of(context).bgBase,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.of(context).border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 14),
              child: Row(
                children: [
                  const Icon(Icons.tune_outlined, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text('Add Adjustment',
                      style: GoogleFonts.lora(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.of(context).fg)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.of(context).fg2, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current: ${widget.entry.hours.toStringAsFixed(2)} hrs',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: AppColors.of(context).fg2),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _ToggleButton(
                        label: 'Add',
                        selected: _isAdding,
                        onTap: () => setState(() => _isAdding = true),
                      ),
                      const SizedBox(width: 8),
                      _ToggleButton(
                        label: 'Subtract',
                        selected: !_isAdding,
                        onTap: () => setState(() => _isAdding = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FieldLabel('Hours'),
                  TextField(
                    controller: _hoursCtrl,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.dmSans(
                        color: AppColors.of(context).fg, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '0.25',
                      filled: true,
                      fillColor: AppColors.of(context).bgElevated,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: AppColors.of(context).border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: AppColors.of(context).border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.primary)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      hintStyle: GoogleFonts.dmSans(
                          color: AppColors.of(context).fg3, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _apply,
                      icon: Icon(
                        _isAdding ? Icons.add_circle_outline : Icons.remove_circle_outline,
                        size: 18,
                      ),
                      label: Text('Apply Adjustment',
                          style: GoogleFonts.dmSans(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.of(context).bgElevated,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.of(context).border,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.of(context).fg,
          ),
        ),
      ),
    );
  }
}
