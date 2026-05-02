import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/segmented_toggle_bar.dart';
import 'entries_screen.dart';
import 'expenses_screen.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.of(context).bgBase,
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 8,
            16,
            10,
          ),
          child: SegmentedToggleBar(
            labels: const ['Entries', 'Expenses'],
            selected: _tab == 0 ? 'Entries' : 'Expenses',
            onChanged: (v) => setState(() => _tab = v == 'Entries' ? 0 : 1),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: const [EntriesScreen(), ExpensesScreen()],
          ),
        ),
      ],
    );
  }
}
