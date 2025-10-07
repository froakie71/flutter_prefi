import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class FileSaver {
  static Future<bool> saveText(String filename, String text, String mime) async {
    final bytes = Uint8List.fromList(text.codeUnits);
    return saveBytes(filename, bytes, mime);
  }

  static Future<bool> saveBytes(String filename, Uint8List bytes, String mime) async {
    // Try multiple writable locations
    final List<Future<Directory?>> tryDirs = [
      getApplicationDocumentsDirectory(),
      getExternalStorageDirectory(), // app-specific external dir (Android)
      getTemporaryDirectory(),
    ];

    for (final futureDir in tryDirs) {
      try {
        final dir = await futureDir;
        if (dir == null) continue;
        // Ensure the directory exists
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes, flush: true);
        return true;
      } catch (_) {
        // try next location
      }
    }
    return false;
  }
}
