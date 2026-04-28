import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/log_time_sheet.dart';
import 'screens/dashboard_screen.dart';
import 'screens/jobs_screen.dart';
import 'screens/entries_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const TimeTrackerApp());
}

class TimeTrackerApp extends StatelessWidget {
  const TimeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'Time Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const AppShell(),
      ),
    );
  }
}

// Nav slots: 0=Dashboard, 1=Jobs, 2=Log(action), 3=Entries, 4=Invoices, 5=Settings
// Slot 2 is the center Log Time button — not a screen.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0; // active tab: 0..5, skip 2

  static const _screens = [
    DashboardScreen(),
    JobsScreen(),
    SizedBox.shrink(), // unused — log is an action
    EntriesScreen(),
    InvoicesScreen(),
    SettingsScreen(),
  ];

  static const _labels = ['Home', 'Jobs', '', 'Entries', 'Invoices', 'Settings'];
  static const _icons = [
    Icons.dashboard_outlined,
    Icons.work_outline,
    null,
    Icons.list_alt_outlined,
    Icons.receipt_long_outlined,
    Icons.settings_outlined,
  ];

  Widget _screen(int navIdx) {
    const map = [0, 1, 0, 2, 3, 4]; // navIdx -> IndexedStack index
    return IndexedStack(
      index: map[_index],
      children: const [
        DashboardScreen(),
        JobsScreen(),
        EntriesScreen(),
        InvoicesScreen(),
        SettingsScreen(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const screenMap = [0, 1, 0, 2, 3, 4];

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: IndexedStack(
        index: screenMap[_index],
        children: const [
          DashboardScreen(),
          JobsScreen(),
          EntriesScreen(),
          InvoicesScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgBase,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 62,
            child: Row(
              children: List.generate(6, (i) {
                if (i == 2) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => LogTimeSheet.show(context),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                  );
                }

                final active = _index == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _index = i),
                    child: Container(
                      color: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _icons[i],
                            size: 19,
                            color: active ? AppColors.primary : AppColors.fg3,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _labels[i],
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                              color: active ? AppColors.primary : AppColors.fg3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
