import re

with open('pubspec.yaml', 'r') as f:
    pub = f.read()

pub = pub.replace("\ndependency_overrides:\n  analyzer: 12.1.0\n  meta: 1.18.3\n", "")

with open('pubspec.yaml', 'w') as f:
    f.write(pub)

print('Removed override')
