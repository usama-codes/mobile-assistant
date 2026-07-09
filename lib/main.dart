import 'package:flutter/material.dart';
import 'package:mobile_assistant/features/chat/chat_vu.dart';
import 'package:mobile_assistant/features/settings/settings_vu.dart';
import 'package:mobile_assistant/features/tasks/task_vu.dart';
import 'package:mobile_assistant/features/documents/documents_vu.dart';
import 'package:mobile_assistant/features/lock/lock_screen_vu.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Could not load .env file: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  
  static _MyAppState of(BuildContext context) => context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mobile Assistant',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFF1D4ED8), 
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        fontFamily: 'Roboto', 
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF82B1FF), // Softer blue for dark mode
          surface: const Color(0xFF1E1E1E), // Softer surface
        ),
        scaffoldBackgroundColor: const Color(0xFF121212), // Elegant softer dark background
        cardColor: const Color(0xFF1E1E1E), // Soft dark card color
        dividerColor: Colors.white24, // Softer divider
        fontFamily: 'Roboto', 
      ),
      home: const LockScreenVU(), // Start with lock screen!
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  int index = 0;

  final List<Widget> pages = [const ChatVU(), const TaskVU(), const DocumentsVU(), const SettingsVU()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1.0,
            ),
          ),
        ),
        child: SafeArea(
          child: SalomonBottomBar(
            currentIndex: index,
            onTap: (i) => setState(() => index = i),
            backgroundColor: Theme.of(context).cardColor,
            items: [
              SalomonBottomBarItem(
                icon: const Icon(Icons.chat_bubble_outline),
                title: const Text("Chat"),
                selectedColor: const Color(0xFF1D4ED8),
                unselectedColor: Colors.grey.shade500,
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.check_box_outlined),
                title: const Text("Tasks"),
                selectedColor: const Color(0xFF1D4ED8),
                unselectedColor: Colors.grey.shade500,
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.folder_open_outlined),
                title: const Text("Docs"),
                selectedColor: const Color(0xFF1D4ED8),
                unselectedColor: Colors.grey.shade500,
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.settings_outlined),
                title: const Text("Settings"),
                selectedColor: const Color(0xFF1D4ED8),
                unselectedColor: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
