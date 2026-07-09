import os

def fix_chat_vu2():
    file_path = 'lib/features/chat/chat_vu.dart'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Input field container color
    content = content.replace('color: const Color(0xFFF9FAFB),', 'color: theme.scaffoldBackgroundColor,')
    content = content.replace('border: Border.all(color: Colors.grey.shade300),', 'border: Border.all(color: theme.dividerColor),')
    
    # PopupMenuButton
    content = content.replace('color: Colors.white,', 'color: theme.cardColor,')
    content = content.replace('surfaceTintColor: Colors.white,', 'surfaceTintColor: theme.cardColor,')
    content = content.replace('color: Color(0xFFF3F4F6)', 'color: theme.scaffoldBackgroundColor')
    
    # User message bubbles 
    # color: isUser ? theme.colorScheme.primary : const Color(0xFFE5E7EB),
    content = content.replace('color: isUser ? theme.colorScheme.primary : const Color(0xFFE5E7EB),', 'color: isUser ? theme.colorScheme.primary : theme.cardColor,')
    
    # Remove some hardcoded Colors.black87
    content = content.replace('color: Colors.black87', 'color: theme.iconTheme.color')

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

fix_chat_vu2()
