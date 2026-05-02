import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/active_timer.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class ActiveTimerCard extends StatefulWidget {
  final ActiveTimer timer;
  const ActiveTimerCard({super.key, required this.timer});

  @override
  State<ActiveTimerCard> createState() => _ActiveTimerCardState();
}

class _ActiveTimerCardState extends State<ActiveTimerCard> {
  late Timer _tick;
  bool _clockingOut = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  String _elapsed() {
    final now = DateTime.now();
    final total = now.difference(widget.timer.startedAt);
    final breakSecs = widget.timer.totalBreakSeconds +
        (widget.timer.breakStartedAt != null
            ? now.difference(widget.timer.breakStartedAt!).inSeconds
            : 0);
    final billable = Duration(
        seconds: (total.inSeconds - breakSecs).clamp(0, total.inSeconds));
    final h = billable.inHours;
    final m = billable.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = billable.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.timer;
    final provider = context.read<AppProvider>();
    final job = provider.jobs.where((j) => j.id == t.jobId).firstOrNull;
    final onBreak = t.isOnBreak;

    final cardColor =
        onBreak ? AppColors.of(context).bgCard : AppColors.success.withAlpha(18);
    final borderColor =
        onBreak ? AppColors.of(context).border : AppColors.success.withAlpha(70);
    final dotColor = onBreak ? AppColors.of(context).fg3 : AppColors.success;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                onBreak ? 'ON BREAK' : 'CLOCKED IN',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: onBreak ? AppColors.of(context).fg3 : AppColors.success,
                ),
              ),
              const Spacer(),
              Text(
                _elapsed(),
                style: GoogleFonts.lora(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: onBreak ? AppColors.of(context).fg2 : AppColors.success,
                ),
              ),
            ],
          ),
          if (job != null) ...[
            const SizedBox(height: 4),
            Text(
              job.name,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.of(context).fg,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBreak
                      ? () => context.read<AppProvider>().endBreak(t.id)
                      : () => context.read<AppProvider>().startBreak(t.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.of(context).fg2,
                    side: BorderSide(color: AppColors.of(context).border),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    onBreak ? 'End Break' : 'Start Break',
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _clockingOut
                      ? null
                      : () async {
                          setState(() => _clockingOut = true);
                          try {
                            await context.read<AppProvider>().clockOut(t.id);
                          } catch (_) {
                            if (mounted) {
                              setState(() => _clockingOut = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Clock out failed — check your connection and try again'),
                                  backgroundColor: Color(0xFFE53935),
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: _clockingOut
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          'Clock Out',
                          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
