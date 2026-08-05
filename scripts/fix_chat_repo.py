import re

with open('lib/features/chat/data/chat_repository.dart', 'r') as f:
    code = f.read()

code = code.replace("import 'package:mobile_assistant/shared/models/chat_session.dart';", "import 'package:mobile_assistant/shared/models/chat_session.dart' as dom;")
code = code.replace("import 'package:mobile_assistant/shared/models/chat_message.dart';", "import 'package:mobile_assistant/shared/models/chat_message.dart' as dom;")
code = code.replace("List<ChatSession>", "List<dom.ChatSession>")
code = code.replace("Future<ChatSession>", "Future<dom.ChatSession>")
code = code.replace("Stream<ChatSession>", "Stream<dom.ChatSession>")
code = code.replace(" ChatSession ", " dom.ChatSession ")
code = code.replace("(ChatSession session)", "(dom.ChatSession session)")

code = code.replace("List<ChatMessage>", "List<dom.ChatMessage>")
code = code.replace("Future<ChatMessage>", "Future<dom.ChatMessage>")
code = code.replace("Stream<ChatMessage>", "Stream<dom.ChatMessage>")
code = code.replace(" ChatMessage ", " dom.ChatMessage ")
code = code.replace("(ChatMessage message)", "(dom.ChatMessage message)")

code = code.replace("dom.ChatSession toDomain() {", "dom.ChatSession toDomain() {")
code = code.replace("return ChatSession(", "return dom.ChatSession(")
code = code.replace("dom.ChatMessage toDomain() {", "dom.ChatMessage toDomain() {")
code = code.replace("return ChatMessage(", "return dom.ChatMessage(")

# In Drift, the data class generated for ChatSessions is ChatSession, not ChatSessionData
code = code.replace("ChatSessionDataExtension", "ChatSessionExtension")
code = code.replace("ChatSessionData", "ChatSession")

with open('lib/features/chat/data/chat_repository.dart', 'w') as f:
    f.write(code)

print('Fixed chat repo!')
