abstract class FileExporter {
  static void exportFile(String filename, String content, {String mimeType = 'text/csv'}) {
    throw UnsupportedError('Cannot export file without platform implementation');
  }
}
