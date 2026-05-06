import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/time_entry.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'field_label.dart';
import 'rate_input_field.dart';

class EntryEditFormSheet extends StatefulWidget {
  final TimeEntry entry;

  const EntryEditFormSheet({super.key, required this.entry});

  static Future<void> show(BuildContext context, TimeEntry entry) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EntryEditFormSheet(entry: entry),
    );
  }

  @override
  State<EntryEditFormSheet> createState() => _EntryEditFormSheetState();
}

class _EntryEditFormSheetState extends State<EntryEditFormSheet> {
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _descCtrl;

  bool get _isTimeBased =>
      !(widget.entry.startTime == '00:00' && widget.entry.endTime == '00:00');

  @override
  void initState() {
    super.initState();
    final dp = widget.entry.date.split('-');
    _date = DateTime(int.parse(dp[0]), int.parse(dp[1]), int.parse(dp[2]));

    final sp = widget.entry.startTime.split(':');
    _startTime =
        TimeOfDay(hour: int.parse(sp[0]), minute: int.parse(sp[1]));

    final ep = widget.entry.endTime.split(':');
    _endTime = TimeOfDay(hour: int.parse(ep[0]), minute: int.parse(ep[1]));

    _hoursCtrl =
        TextEditingController(text: widget.entry.hours.toStringAsFixed(2));
    _rateCtrl = TextEditingController(
        text: widget.entry.rateOverride?.toStringAsFixed(2) ?? '');
    _descCtrl = TextEditingController(text: widget.entry.description);
  }

  @override
  void dispose() {
    _hoursCtrl.dispose();
    _rateCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _pad2(int n) => n.toString().padLeft(2, '0');

  double _computeHours() {
    final startMins = _startTime.hour * 60 + _startTime.minute;
    var endMins = _endTime.hour * 60 + _endTime.minute;
    if (endMins <= startMins) endMins += 24 * 60;
    return (endMins - startMins) / 60.0;
  }

  String _fmt12(TimeOfDay t) {
    final period = t.hour < 12 ? 'AM' : 'PM';
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h12:${_pad2(t.minute)} $period';
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked =
        await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _save() {
    final provider = context.read<AppProvider>();
    final dateStr =
        '${_date.year}-${_pad2(_date.month)}-${_pad2(_date.day)}';

    final double hours;
    final String startStr, endStr;

    if (_isTimeBased) {
      hours = _computeHours();
      startStr = '${_pad2(_startTime.hour)}:${_pad2(_startTime.minute)}';
      endStr = '${_pad2(_endTime.hour)}:${_pad2(_endTime.minute)}';
    } else {
      hours =
          double.tryParse(_hoursCtrl.text.trim()) ?? widget.entry.hours;
      startStr = '00:00';
      endStr = '00:00';
    }

    final rateText = _rateCtrl.text.trim();
    final rate = rateText.isEmpty ? null : double.tryParse(rateText);

    provider.updateEntry(
      widget.entry.id,
      date: dateStr,
      startTime: startStr,
      endTime: endStr,
      hours: hours,
      rateOverride: rate,
      clearRateOverride: rate == null,
      description: _descCtrl.text.trim(),
    );
    Navigator.pop(context);
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.of(context).bgElevated,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.of(context).border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.of(context).border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle:
            GoogleFonts.dmSans(color: AppColors.of(context).fg3, fontSize: 13),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.of(context).bgBase,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
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
                  const Icon(Icons.edit_note,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text('Edit Entry',
                      style: GoogleFonts.lora(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.of(context).fg)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: AppColors.of(context).fg2, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FieldLabel('Date'),
                    _TapField(
                      value: _formatDate(_date),
                      icon: Icons.calendar_today_outlined,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 16),
                    if (_isTimeBased) ...[
                      FieldLabel('Start Time'),
                      _TapField(
                        value: _fmt12(_startTime),
                        icon: Icons.schedule_outlined,
                        onTap: () => _pickTime(true),
                      ),
                      const SizedBox(height: 16),
                      FieldLabel('End Time'),
                      _TapField(
                        value: _fmt12(_endTime),
                        icon: Icons.schedule_outlined,
                        onTap: () => _pickTime(false),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          '${_computeHours().toStringAsFixed(2)} hrs computed from times',
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.of(context).fg2),
                        ),
                      ),
                    ] else ...[
                      FieldLabel('Hours Worked'),
                      TextField(
                        controller: _hoursCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: GoogleFonts.dmSans(
                            color: AppColors.of(context).fg, fontSize: 13),
                        decoration: _inputDec('0.00'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FieldLabel('Hourly Rate Override (Optional)'),
                    RateInputField(controller: _rateCtrl),
                    const SizedBox(height: 16),
                    FieldLabel('Notes / Description'),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      style: GoogleFonts.dmSans(
                          color: AppColors.of(context).fg, fontSize: 13),
                      decoration: _inputDec('What did you work on?'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check, size: 18),
                        label: Text('Save Changes',
                            style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _TapField extends StatelessWidget {
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _TapField(
      {required this.value, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.of(context).bgElevated,
          border: Border.all(color: AppColors.of(context).border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.of(context).fg2),
            const SizedBox(width: 8),
            Expanded(
              child: Text(value,
                  style: GoogleFonts.dmSans(
                      color: AppColors.of(context).fg, fontSize: 13)),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: AppColors.of(context).fg3),
          ],
        ),
      ),
    );
  }
}
