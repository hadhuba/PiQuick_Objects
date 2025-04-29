import 'dart:typed_data';
import 'package:web/web.dart';
import 'dart:js_interop';

void downloadFile(Uint8List bytes, String fileName) {
  // Convert Uint8List to a JSArray compatible with BlobPart
  final blobParts = [bytes.toJS];

  // Create a blob from bytes
  final blob = Blob(blobParts as JSArray<BlobPart>);

  // Create a URL for the blob
  final url = URL.createObjectURL(blob);

  // Create an anchor element for downloading
  final anchor = document.createElement('a') as HTMLAnchorElement;
  anchor.href = url;
  anchor.style.display = 'none';
  anchor.setAttribute('download', fileName);

  // Add to the document and click
  document.body!.appendChild(anchor);
  anchor.click();

  // Clean up
  anchor.remove();
  URL.revokeObjectURL(url);
}
