import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'date_picker_button.dart';
import 'field_label.dart';
import 'job_picker_dropdown.dart';
import 'segmented_toggle_bar.dart';

class LogTimeSheet extends StatefulWidget {
  final String? preJobId;
  final double? preHours;
  final VoidCallback? onConfirmSave;
  const LogTimeSheet({super.key, this.preJobId, this.preHours, this.onConfirmSave});

  static Future<void> show(BuildContext context, {String? preJobId, double? preHours, VoidCallback? onConfirmSave}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogTimeSheet(preJobId: preJobId, preHours: preHours, onConfirmSave: onConfirmSave),
    );
  }

  @override
  State<LogTimeSheet> createState() => _LogTimeSheetState();
}

class _LogTimeSheetState extends State<LogTimeSheet> {
  late String _jobId;
  String _date = DateTime.now().toIso8601String().substring(0, 10);
  String _startTime = '08:00';
  String _endTime = '10:00';
  String _description = '';
  bool _useManual = false;
  double _manualHours = 0;

  final _descController = TextEditingController();
  final _manualController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    final activeJobs = provider.jobs.where((j) => !j.isArchived).toList();
    _jobId = widget.preJobId ?? (activeJobs.isNotEmpty ? activeJobs.first.id : '');
    if (widget.preHours != null && widget.preHours! > 0) {
      _useManual = true;
      _manualHours = widget.preHours!;
      _manualController.text = widget.preHours!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  double get _calculatedHours {
    if (_useManual) return _manualHours;
    final start = _parseTime(_startTime);
    final end = _parseTime(_endTime);
    final diff = end - start;
    return diff > 0 ? diff / 60.0 : 0;
  }

  int _parseTime(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_date),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: AppTheme.dark.copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.of(context).bgCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _date = picked.toIso8601String().substring(0, 10));
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final parts = (isStart ? _startTime : _endTime).split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      builder: (context, child) => Theme(
        data: AppTheme.dark.copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.of(context).bgCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _startTime = formatted;
        } else {
          _endTime = formatted;
        }
      });
    }
  }

  void _save() {
    final hours = _calculatedHours;
    if (_jobId.isEmpty || hours <= 0) return;
    context.read<AppProvider>().addEntry(
          jobId: _jobId,
          date: _date,
          startTime: _startTime,
          endTime: _endTime,
          hours: hours,
          description: _description,
        );
    widget.onConfirmSave?.call();
    Navigator.pop(context);
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.of(context).bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.of(context).border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.of(context).border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: GoogleFonts.dmSans(color: AppColors.of(context).fg3, fontSize: 13),
      );

  Widget _label(String text) => FieldLabel(text);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final activeJobs = provider.jobs.where((j) => !j.isArchived).toList();
    final hours = _calculatedHours;
    final canSave = _jobId.isNotEmpty && hours > 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: AppColors.of(context).bgBase,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.of(context).border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 14),
              child: Row(
                children: [
                  Text('Log Time', style: GoogleFonts.lora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.of(context).fg2, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Scrollable content
            Expanded(
              child: ListView(
                controller: controller,
                padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 32),
                children: [
                  // Job picker
                  _label('Job'),
                  JobPickerDropdown(
                    jobs: activeJobs,
                    selectedJobId: _jobId.isEmpty ? null : _jobId,
                    allowDeselect: false,
                    maxDropdownHeight: 200,
                    onJobSelected: (id) {
                      if (id != null) setState(() => _jobId = id);
                    },
                    onAddJob: () => _addJobInline(context.read<AppProvider>()),
                  ),
                  const SizedBox(height: 16),

                  // Date
                  _label('Date'),
                  DatePickerButton(
                    label: _formatDateDisplay(_date),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 16),

                  // Time mode toggle
                  _label('Time'),
                  SegmentedToggleBar(
                    labels: const ['Start & End', 'Enter Duration'],
                    selected: _useManual ? 'Enter Duration' : 'Start & End',
                    onChanged: (v) => setState(() => _useManual = v == 'Enter Duration'),
                  ),
                  const SizedBox(height: 10),
                  if (_useManual)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.dmSans(color: AppColors.of(context).fg, fontSize: 13),
                            decoration: _inputDec('0.0'),
                            onChanged: (v) => setState(() => _manualHours = double.tryParse(v) ?? 0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('hours', style: GoogleFonts.dmSans(color: AppColors.of(context).fg2, fontSize: 13)),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(child: _timeTile(_startTime, () => _pickTime(true))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('to', style: GoogleFonts.dmSans(color: AppColors.of(context).fg2, fontSize: 13)),
                        ),
                        Expanded(child: _timeTile(_endTime, () => _pickTime(false))),
                      ],
                    ),
                  if (hours > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${hours.toStringAsFixed(2)} hours calculated',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Description
                  _label('Description of work'),
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    style: GoogleFonts.dmSans(color: AppColors.of(context).fg, fontSize: 13),
                    decoration: _inputDec('What did you do?'),
                    onChanged: (v) => _description = v,
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canSave ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canSave ? AppColors.accent : AppColors.of(context).fg3,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text('Save Entry', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700)),
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

  Future<void> _addJobInline(AppProvider provider) async {
    // Use a ValueNotifier so we can read the name after the dialog closes
    // without holding a TextEditingController reference past its widget's life.
    String pendingName = '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        final ctrl = TextEditingController();
        return AlertDialog(
          backgroundColor: AppColors.of(context).bgBase,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('New Job', style: GoogleFonts.lora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            style: GoogleFonts.dmSans(color: AppColors.of(context).fg, fontSize: 13),
            onChanged: (v) => pendingName = v,
            decoration: InputDecoration(
              hintText: 'Job name',
              hintStyle: GoogleFonts.dmSans(color: AppColors.of(context).fg3, fontSize: 13),
              filled: true,
              fillColor: AppColors.of(context).bgElevated,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.of(context).border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.of(context).border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.dmSans(color: AppColors.of(context).fg2))),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text.trim().isEmpty) return;
                pendingName = ctrl.text.trim();
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Add', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            ),
          ],
        );
        // ctrl is owned by the AlertDialog's State and disposed when that State disposes
      },
    );

    final name = pendingName.trim();
    if (confirmed == true && name.isNotEmpty) {
      provider.addJob(name, '', null);
      final newJob = provider.jobs.lastWhere((j) => j.name == name);
      setState(() => _jobId = newJob.id);
    }
  }


  String _fmt12(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = parts[1];
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $period';
  }

  Widget _timeTile(String time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: AppColors.of(context).bgElevated,
          border: Border.all(color: AppColors.of(context).border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(_fmt12(time), style: GoogleFonts.dmSans(color: AppColors.of(context).fg, fontSize: 13)),
      ),
    );
  }

  String _formatDateDisplay(String date) {
    final d = DateTime.parse(date);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
    return '${days[d.weekday % 7]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
