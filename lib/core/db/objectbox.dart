import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_assistant/objectbox.g.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ObjectBox {
  ObjectBox._create(this.store);
  late final Store store;

  static Future<ObjectBox> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store = await openStore(
      directory: p.join(docsDir.path, 'obx-memories'),
    );
    return ObjectBox._create(store);
  }
}

final objectBoxProvider = Provider<ObjectBox>((ref) {
  throw UnimplementedError('objectBoxProvider must be overridden in main.dart');
});
