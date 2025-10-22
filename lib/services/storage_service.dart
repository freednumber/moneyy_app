import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StorageService {
  Future<String> saveReceiptImage(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(p.join(dir.path, 'receipts'));
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }
    final filename = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
    final dest = File(p.join(receiptsDir.path, filename));
    await file.copy(dest.path);
    return dest.uri.toString();
  }
}
