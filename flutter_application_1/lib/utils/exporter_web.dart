import 'dart:html' as html;
import 'dart:convert';

class FileExporter {
  static void exportFile(String filename, String content, {String mimeType = 'text/csv'}) {
    // Include UTF-8 BOM so Excel opens it with correct Vietnamese diacritics encoding
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
