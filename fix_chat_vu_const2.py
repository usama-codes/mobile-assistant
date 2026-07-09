import os
import re

def fix_chat_vu_const_more():
    file_path = 'lib/features/chat/chat_vu.dart'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find and remove 'const ' where 'theme.' is used
    # A simple regex for const ... theme...
    content = re.sub(r'const\s+([A-Za-z0-9_]+)\([^)]*theme\.[^)]*\)', lambda m: m.group(0).replace('const ', ''), content)
    
    # Let's just blindly remove 'const ' from lines with 'theme.' just in case it's in a deeply nested thing.
    # Actually, the error lines are:
    # 25, 65, 67, 324, 343
    
    lines = content.split('\n')
    for i in [24, 64, 66, 323, 342]:
        if i < len(lines):
            lines[i] = lines[i].replace('const ', '')
            
    content = '\n'.join(lines)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

fix_chat_vu_const_more()
