import 'dart:io';

class StorageService {
  // No permanent storage - just use temp file from picker
  // Return file:// URI for local processing
  Future<String> getImageUri(File file) async {
    return file.uri.toString();
  }
  
  // Clean up temp file after transaction is saved
  Future<void> cleanupTempFile(String fileUri) async {
    try {
      if (fileUri.startsWith('file://')) {
        final file = File(Uri.parse(fileUri).toFilePath());
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}
