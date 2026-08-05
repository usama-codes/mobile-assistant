// ignore_for_file: avoid_print

import 'dart:io';

import 'package:mobile_assistant/core/db/database.dart';

void main() async {
  final db = AppDatabase();
  final messages = await db.select(db.messages).get();
  for (var m in messages) {
    print('ID: ${m.id}, Session: ${m.sessionId}, isUser: ${m.isUser}, Content: ${m.content}');
  }
  exit(0);
}
