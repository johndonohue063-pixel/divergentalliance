import 'dart:convert' as convert;
import 'dart:html' as html;

Future<void> downloadTextFileWeb(String filename, String content) async {
  final safeName = filename.isEmpty ? 'report.csv' : filename;
  final safeContent = content.isEmpty ? 'Cluster,County,State\n' : content;
  final bytes = convert.utf8.encode(safeContent);
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final a = html.AnchorElement(href: url)..download = safeName..style.display = 'none';
  html.document.body?.append(a); a.click(); a.remove();
  html.Url.revokeObjectUrl(url);
}
String get kBaseUrl => 'http://127.0.0.1:8010';
