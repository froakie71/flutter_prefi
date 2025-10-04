// Only compiled on web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

class FileSaver {
  static Future<bool> saveText(String filename, String text, String mime) async {
    final bytes = Uint8List.fromList(text.codeUnits);
    return saveBytes(filename, bytes, mime);
  }

  static Future<bool> saveBytes(String filename, Uint8List bytes, String mime) async {
    final blob = html.Blob([bytes], mime);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    return true;
  }
}
