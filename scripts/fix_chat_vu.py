import os

def fix_chat_vu():
    file_path = 'lib/features/chat/chat_vu.dart'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Apply Theme.of(context) where appropriate in the builder method
    # It's a bit tricky to do a blind replace, so let's do targeted replacements.
    
    # 1. Insert final theme = Theme.of(context); at the beginning of builder
    if 'final theme = Theme.of(context);' not in content:
        content = content.replace('Widget builder(BuildContext context, ChatVM vm, Widget? child) {\n    return Scaffold(', 'Widget builder(BuildContext context, ChatVM vm, Widget? child) {\n    final theme = Theme.of(context);\n    return Scaffold(')
    
    # 2. Replace hardcoded colors in Scaffold
    content = content.replace('backgroundColor: const Color(0xFFF9FAFB),', 'backgroundColor: theme.scaffoldBackgroundColor,')
    content = content.replace('backgroundColor: Colors.white,', 'backgroundColor: theme.cardColor,')
    
    # Drawer background
    content = content.replace('drawer: Drawer(\n        backgroundColor: Colors.white,', 'drawer: Drawer(\n        backgroundColor: theme.scaffoldBackgroundColor,')
    
    # AppBar bottom border
    content = content.replace('child: Container(color: Colors.grey.shade200, height: 1.0),', 'child: Container(color: theme.dividerColor, height: 1.0),')
    
    # AppBar text colors
    content = content.replace("const Text('Assistant', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24))", "Text('Assistant', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 24))")
    content = content.replace("Text(\n              'Always here to help',\n              style: TextStyle(color: Colors.grey.shade600,", "Text(\n              'Always here to help',\n              style: TextStyle(color: theme.textTheme.bodySmall?.color,")
    
    # Text Input field container
    content = content.replace('decoration: BoxDecoration(\n              color: Colors.white,', 'decoration: BoxDecoration(\n              color: theme.cardColor,')
    
    # Send button color
    content = content.replace('color: const Color(0xFF1D4ED8)', 'color: theme.colorScheme.primary')
    
    # Input decoration
    content = content.replace('hintStyle: const TextStyle(color: Colors.grey)', 'hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color)')
    content = content.replace('style: const TextStyle(color: Colors.black)', 'style: TextStyle(color: theme.textTheme.bodyLarge?.color)')

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

fix_chat_vu()
