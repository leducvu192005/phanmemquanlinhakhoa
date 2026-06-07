import 'dart:io';

class FileExporter {
  static void exportFile(String filename, String content, {String mimeType = 'text/csv'}) {
    try {
      // Try to save directly to the user's Downloads directory on Mac
      final downloadsDir = Directory('/Users/leducvu/Downloads');
      File file;
      if (downloadsDir.existsSync()) {
        file = File('${downloadsDir.path}/$filename');
      } else {
        file = File('./$filename');
      }
      
      // Write with UTF-8 BOM so Excel opens it correctly
      file.writeAsBytesSync([0xEF, 0xBB, 0xBF, ...content.codeUnits]);
      print('File saved successfully to: ${file.absolute.path}');
    } catch (e) {
      print('Failed to save file: $e');
    }
  }
}
