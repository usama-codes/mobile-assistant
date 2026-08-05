import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_assistant/features/settings/presentation/settings_provider.dart';
import 'package:mobile_assistant/core/db/objectbox.dart';
import 'package:mobile_assistant/core/services/analytics_service.dart';
import 'package:mobile_assistant/core/services/inference_service.dart';
import 'package:mobile_assistant/core/services/migration_service.dart';
import 'package:mobile_assistant/core/services/notification_service.dart';
import 'package:mobile_assistant/core/services/vault_service.dart';
import 'package:mobile_assistant/core/theme/app_theme.dart';
import 'package:mobile_assistant/features/chat/presentation/chat_screen.dart';
import 'package:mobile_assistant/features/lock/presentation/screens/lock_screen.dart';
import 'package:mobile_assistant/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mobile_assistant/features/settings/presentation/settings_screen.dart';
import 'package:mobile_assistant/features/tasks/presentation/tasks_screen.dart';
import 'package:mobile_assistant/features/vault/presentation/vault_screen.dart';
import 'package:mobile_assistant/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await VaultService.instance.initialize();
  await MigrationService.runMigrations();
  await InferenceService.instance.initialize();
  await NotificationService.instance.initialize();
  try {
    await dotenv.load();
  } catch (e) {
    logger.e('Could not load .env file', error: e);
  }

  // try {
  //   await Firebase.initializeApp();
  //   FlutterError.onError = AnalyticsService().recordFlutterFatalError;
  // } catch (e) {
  //   logger.e('Firebase init failed', error: e);
  // }

  final objectBox = await ObjectBox.create();

  runApp(
    ProviderScope(
      overrides: [objectBoxProvider.overrideWithValue(objectBox)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  // ignore: library_private_types_in_public_api
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Read saved theme from settings (dark by default until loaded)
    final settingsAsync = ref.watch(settingsProvider);
    final themeMode = settingsAsync.maybeWhen(
      data: (s) => s.themeMode,
      orElse: () => _themeMode,
    );
    // Enforce immersive dark status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mobile Assistant',
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ur')],
      home: InferenceService.instance.isLocalModelLoaded
          ? const LockScreen()
          : const OnboardingScreen(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const List<ConsumerStatefulWidget> _pages = [
    ChatScreen(),
    TasksScreen(),
    VaultScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _index, children: _pages),
      extendBody: true, // content flows behind floating nav
      bottomNavigationBar: _PillNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

// ── Floating Pill Navigation Bar ──────────────────────────────────────────

class _PillNav extends StatelessWidget {
  const _PillNav({required this.currentIndex, required this.onTap});
  final int currentIndex;
  final void Function(int) onTap;

  static const List<Map<String, Object?>> _items = [
    {
      'active': Icons.chat_bubble_rounded,
      'inactive': Icons.chat_bubble_outline_rounded,
      'label': 'Chat',
    },
    {
      'active': Icons.check_circle_rounded,
      'inactive': Icons.check_circle_outline_rounded,
      'label': 'Tasks',
    },
    {
      'active': Icons.lock_rounded,
      'inactive': Icons.lock_outline_rounded,
      'label': 'Vault',
    },
    {
      'active': Icons.settings_rounded,
      'inactive': Icons.settings_outlined,
      'label': 'Settings',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            selected
                                ? (item['active']! as IconData)
                                : (item['inactive']! as IconData),
                            key: ValueKey(selected),
                            size: 22,
                            color: selected
                                ? AppTheme.accent
                                : Theme.of(context).disabledColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: selected
                                ? AppTheme.accent
                                : Theme.of(context).disabledColor,
                          ),
                          child: Text(item['label']! as String),
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
    );
  }
}
