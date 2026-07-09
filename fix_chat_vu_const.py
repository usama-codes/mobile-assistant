import os
import re

def fix_chat_vu_const():
    file_path = 'lib/features/chat/chat_vu.dart'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove invalid const before BoxDecoration when using theme
    content = content.replace('decoration: const BoxDecoration(\n                            color: theme.scaffoldBackgroundColor,', 'decoration: BoxDecoration(\n                            color: theme.scaffoldBackgroundColor,')
    
    # Remove invalid const before Icon when using theme
    content = content.replace('child: const Icon(Icons.send, color: theme.cardColor, size: 20),', 'child: Icon(Icons.send, color: theme.cardColor, size: 20),')

    # Also _buildShortcut needs 	heme parameter or just context
    content = content.replace('Widget _buildShortcut(ChatVM vm, String title) {', 'Widget _buildShortcut(BuildContext context, ChatVM vm, String title) {\n    final theme = Theme.of(context);')
    content = content.replace('_buildShortcut(vm, ', '_buildShortcut(context, vm, ')

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

fix_chat_vu_const()
