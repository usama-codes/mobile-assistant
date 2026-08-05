import re

with open('lib/features/chat/data/chat_repository.dart', 'r') as f:
    code = f.read()

repo_add = '''
  Future<void> clearMessagesForSession(int sessionId) async {
    await (_db.delete(_db.messages)..where((m) => m.sessionId.equals(sessionId))).go();
  }

  Future<void> deleteMessage(int id) async {
    await (_db.delete(_db.messages)..where((m) => m.id.equals(id))).go();
  }
}
'''
code = code.replace("}\n\nextension ChatSessionDataExtension", repo_add + "\nextension ChatSessionDataExtension")

with open('lib/features/chat/data/chat_repository.dart', 'w') as f:
    f.write(code)

with open('lib/features/chat/presentation/chat_provider.dart', 'r') as f:
    provider = f.read()

provider_add = '''
  Future<void> clearChat() async {
    if (state.currentSession == null) return;
    await _repository.clearMessagesForSession(state.currentSession!.id!);
    state = state.copyWith(messages: []);
  }

  Future<void> deleteMessage(int id) async {
    await _repository.deleteMessage(id);
    final messages = state.messages.where((m) => m.id != id).toList();
    state = state.copyWith(messages: messages);
  }
}
'''

provider = re.sub(r'  Future<void> clearChat\(\) async \{.*?\n\}\n', provider_add, provider, flags=re.DOTALL)
with open('lib/features/chat/presentation/chat_provider.dart', 'w') as f:
    f.write(provider)

print('Added repo methods!')
