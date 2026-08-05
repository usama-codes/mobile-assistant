import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_assistant/main.dart' as app;
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'app starts and navigates through tabs',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      // Ensure the app started on the home/chat tab
      expect($('Mobile Assistant'), findsWidgets);

      // Tap on Tasks tab (assuming it's a BottomNavigationBar item with text "Tasks" or icon)
      // Since it's a bottom nav, we can tap the tab by text
      await $(Icons.task_alt).tap();
      await $.pumpAndSettle();

      // Check if TasksScreen is active
      expect($('Tasks'), findsWidgets);
      
      // Tap on Chat tab
      await $(Icons.chat).tap();
      await $.pumpAndSettle();

      // Check if ChatScreen is active
      expect($('Agent'), findsWidgets);
    },
  );
}
