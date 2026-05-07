import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/time_entry.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'field_label.dart';

class AddBreakSheet extends StatefulWidget {
  final TimeEntry entry;

  const AddBreakSheet({super.key, required this.entry});

  static Future<void> show(BuildContext context, TimeEntry entry) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBreakSheet(entry: entry),
    );
  }

  @override
  State<AddBreakSheet> createState() => _AddBreakSheetState();
}

class _AddBreakSheetState extends State<AddBreakSheet> {
  final _minutesCtrl = TextEditingController();

  @override
  void dispose() {
    _minutesCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final minutes = int.tryParse(_minutesCtrl.text.trim()) ?? 0;
    if (minutes <= 0) return;
    context.read<AppProvider>().addBreak(widget.entry.id, minutes);
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
                  const Icon(Icons.coffee_outlined, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text('Add Break',
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
                  FieldLabel('Break Duration (minutes)'),
                  TextField(
                    controller: _minutesCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.dmSans(
                        color: AppColors.of(context).fg, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '30',
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
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      label: Text('Deduct Break',
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
