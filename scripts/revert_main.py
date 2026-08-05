import os

def revert_main_dart():
    file_path = 'lib/main.dart'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # We need to replace the custom bottomNavigationBar Container with a standard BottomNavigationBar
    start_str = 'bottomNavigationBar: Container('
    if start_str in content:
        start_idx = content.find(start_str)
        # Find the matching closing brace for bottomNavigationBar
        # The container has child: SafeArea(...) inside it.
        # It ends right before ody: PageView( or similar.
        end_idx = content.find('body: PageView', start_idx)
        
        if start_idx != -1 and end_idx != -1:
            replacement = '''bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          });
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), activeIcon: Icon(Icons.check_circle), label: 'Tasks'),
        ],
      ),
      '''
            content = content[:start_idx] + replacement + content[end_idx:]

    # Remove the _buildNavItem helper method
    method_str = 'Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {'
    if method_str in content:
        start_idx = content.find(method_str)
        end_idx = content.find('}', content.find('}', content.find('}', content.find('}', start_idx)+1)+1)+1)+1
        content = content[:start_idx] + content[end_idx:]

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

revert_main_dart()
