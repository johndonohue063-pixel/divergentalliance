import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadCsvAndOpenFromBackend(Uri uri) async {
  final r = await http.get(uri, headers: {'accept': 'text/csv'}).timeout(const Duration(seconds: 30));
  if (r.statusCode != 200) {
    throw Exception('CSV HTTP ${r.statusCode}: ${r.body}');
  }

  String fileName = 'storm_report_${DateTime.now().millisecondsSinceEpoch}.csv';
  final cd = r.headers['content-disposition'];
  final m = RegExp(r'filename="?([^"]+)"?').firstMatch(cd ?? '');
  if (m != null) fileName = m.group(1)!;

  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/$fileName';
  await File(path).writeAsBytes(r.bodyBytes, flush: true);

  final result = await OpenFilex.open(path, type: 'text/csv');

  // If nothing can open it, show Android's share sheet as a fallback.
  if (result.type != ResultType.done) {
    await Share.shareXFiles([XFile(path, mimeType: 'text/csv')], subject: 'Storm report');
  }
}
