import 'dart:typed_data';

class FileSaver {
  static Future<bool> saveText(String filename, String text, String mime) async {
    return false; // Not supported on this platform
  }

  static Future<bool> saveBytes(String filename, Uint8List bytes, String mime) async {
    return false; // Not supported on this platform
  }
}
