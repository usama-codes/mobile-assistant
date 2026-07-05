import 'package:flutter/material.dart';
import 'package:mobile_assistant/features/chat/chat_vu.dart';
import 'package:mobile_assistant/features/settings/settings_vu.dart';
import 'package:mobile_assistant/features/tasks/task_vu.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Could not load .env file: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mobile Assistant',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: HomePage(),
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

  final List<Widget> pages = [ChatVU(), TaskVU(), SettingsVU()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   leading: IconButton(onPressed: null, icon: Icon(Icons.smart_toy)),
      //   titleSpacing: 60,
      //   // title: Text("Chat With AI"),
      //   actions: [IconButton(icon: Icon(Icons.help), onPressed: null)],
      // ),
      body: pages[index],
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1.0,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SalomonBottomBar(
              currentIndex: index,
              onTap: (i) => setState(() => index = i),
              items: [
                SalomonBottomBarItem(
                  icon: const Icon(Icons.message_outlined, size: 25),
                  title: const Text("Chat"),
                  selectedColor: Colors.deepPurple,
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.task_alt_outlined, size: 25),
                  title: const Text("Tasks"),
                  selectedColor: Colors.blueAccent,
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.settings_outlined, size: 25),
                  title: const Text("Settings"),
                  selectedColor: Colors.teal,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
