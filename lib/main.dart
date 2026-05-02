import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'firebase_platform_init_stub.dart'
    if (dart.library.html) 'firebase_platform_init_web.dart';
import 'providers/app_provider.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/jobs_screen.dart';
import 'screens/log_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/more_screen.dart';

final _authService = AuthService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initFirebasePlatform();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TimeTrackerApp());
}

class TimeTrackerApp extends StatelessWidget {
  const TimeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            title: 'Time Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            home: const _SplashScreen(),
          );
        }
        if (snapshot.data != null) {
          // ChangeNotifierProvider wraps MaterialApp so AppProvider is
          // accessible from any pushed route or modal sheet (above the navigator).
          return ChangeNotifierProvider(
            create: (_) => AppProvider()..load(),
            child: MaterialApp(
              title: 'Time Tracker',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              home: const AppShell(),
            ),
          );
        }
        return MaterialApp(
          title: 'Time Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: const LoginScreen(),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _labels = ['Jobs', 'Log', 'Invoices', 'More'];
  static const _icons = [
    Icons.work_outline,
    Icons.list_alt_outlined,
    Icons.receipt_long_outlined,
    Icons.more_horiz,
  ];

  @override
  Widget build(BuildContext context) {
    final isLoaded = context.watch<AppProvider>().isLoaded;
    if (!isLoaded) {
      return const Scaffold(
        backgroundColor: AppColors.bgDeep,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: IndexedStack(
        index: _index,
        children: const [
          JobsScreen(),
          LogScreen(),
          InvoicesScreen(),
          MoreScreen(),
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
              children: List.generate(4, (i) {
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
                            size: 20,
                            color: active ? AppColors.accent : AppColors.fg2,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _labels[i],
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                              color: active ? AppColors.accent : AppColors.fg2,
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
