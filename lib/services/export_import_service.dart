import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'hive_service.dart';

class ExportImportService {
  static ExportImportService? _instance;
  static ExportImportService get instance => _instance ??= ExportImportService._();

  ExportImportService._();

  Future<String> exportAllToJsonString() async {
    final data = HiveService.instance.exportAllAsJson();
    return jsonEncode(data);
  }

  Future<File> exportToFile({String? fileName}) async {
    final jsonString = await exportAllToJsonString();
    final docs = await getApplicationDocumentsDirectory();
    final name = fileName ?? 'streakly_export_${DateTime.now().toIso8601String()}.json';
    final file = File('${docs.path}/$name');
    await file.writeAsString(jsonString);
    return file;
  }

  Future<void> shareExport() async {
    final file = await exportToFile();
    // Share the JSON as a file so it can be imported on another device.
    final xfile = XFile(file.path);
    await Share.shareXFiles(
      [xfile],
      subject: 'Streakly export',
      text: 'Streakly backup JSON file attached',
    );
  }

  Future<Map<String, dynamic>> importFromJsonString(String jsonString, {bool overwrite = false}) async {
    final Map<String, dynamic> data = jsonDecode(jsonString);

    // Create backup automatically
    final backup = await exportToFile(fileName: 'streakly_backup_before_import_${DateTime.now().toIso8601String()}.json');

    try {
      await HiveService.instance.importJson(data, overwrite: overwrite);
      return {'success': true, 'backup': backup.path};
    } catch (e) {
      // Attempt restore from backup
      try {
        final b = await backup.readAsString();
        final Map<String, dynamic> backupData = jsonDecode(b);
        await HiveService.instance.importJson(backupData, overwrite: true);
      } catch (_) {}
      return {'success': false, 'error': e.toString(), 'backup': backup.path};
    }
  }
}
