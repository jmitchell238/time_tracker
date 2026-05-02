import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/job.dart';
import '../theme/app_theme.dart';

class JobPickerDropdown extends StatefulWidget {
  final List<Job> jobs;
  final String? selectedJobId;
  final void Function(String? jobId) onJobSelected;
  final bool allowDeselect;
  final Future<void> Function()? onAddJob;
  final double maxDropdownHeight;
  final String placeholder;

  const JobPickerDropdown({
    super.key,
    required this.jobs,
    required this.selectedJobId,
    required this.onJobSelected,
    this.allowDeselect = true,
    this.onAddJob,
    this.maxDropdownHeight = 180,
    this.placeholder = 'Select a job…',
  });

  @override
  State<JobPickerDropdown> createState() => _JobPickerDropdownState();
}

class _JobPickerDropdownState extends State<JobPickerDropdown> {
  bool _showPicker = false;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final selectedJob =
        widget.jobs.where((j) => j.id == widget.selectedJobId).firstOrNull;
    final filtered = widget.jobs
        .where((j) => j.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showPicker = !_showPicker),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.of(context).bgElevated,
              border: Border.all(
                  color: _showPicker ? AppColors.primary : AppColors.of(context).border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedJob?.name ?? widget.placeholder,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color:
                          selectedJob != null ? AppColors.of(context).fg : AppColors.of(context).fg3,
                    ),
                  ),
                ),
                if (widget.allowDeselect && widget.selectedJobId != null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      widget.onJobSelected(null);
                      setState(() {
                        _showPicker = false;
                        _search = '';
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child:
                          Icon(Icons.clear, size: 16, color: AppColors.of(context).fg3),
                    ),
                  )
                else
                  Icon(
                    _showPicker ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.of(context).fg2,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
        if (_showPicker) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppColors.of(context).bgCard,
              border: Border.all(color: AppColors.of(context).border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style:
                        GoogleFonts.dmSans(color: AppColors.of(context).fg, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search jobs…',
                      hintStyle:
                          GoogleFonts.dmSans(color: AppColors.of(context).fg3, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Divider(height: 1, color: AppColors.of(context).border),
                ConstrainedBox(
                  constraints:
                      BoxConstraints(maxHeight: widget.maxDropdownHeight),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ...filtered.map((j) {
                        final isSel = j.id == widget.selectedJobId;
                        return InkWell(
                          onTap: () {
                            widget.onJobSelected(j.id);
                            setState(() {
                              _showPicker = false;
                              _search = '';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            color: isSel
                                ? AppColors.primary.withAlpha(38)
                                : Colors.transparent,
                            child: Text(
                              j.name,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: isSel
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color:
                                    isSel ? AppColors.primary : AppColors.of(context).fg,
                              ),
                            ),
                          ),
                        );
                      }),
                      if (widget.onAddJob != null) ...[
                        if (filtered.isNotEmpty)
                          Divider(height: 1, color: AppColors.of(context).border),
                        InkWell(
                          onTap: widget.onAddJob,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 11),
                            child: Row(
                              children: [
                                const Icon(Icons.add,
                                    size: 16, color: AppColors.accent),
                                const SizedBox(width: 8),
                                Text(
                                  'Add new job…',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accent),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
