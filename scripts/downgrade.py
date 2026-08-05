import re

with open('pubspec.yaml', 'r') as f:
    pub = f.read()

pub = pub.replace("  riverpod_generator: ^4.0.4\n", "  riverpod_generator: any\n")

with open('pubspec.yaml', 'w') as f:
    f.write(pub)

print('Downgraded riverpod_generator')
