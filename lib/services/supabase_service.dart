// SupabaseService removed: please migrate code to use `HiveService`.
// This file remains as a stub to avoid breaking imports. Remove imports of
// SupabaseService and replace with `HiveService.instance` methods.

import 'package:flutter/foundation.dart';

@deprecated
class SupabaseService {
  SupabaseService._();

  static Future<void> initialize() async {
    if (kDebugMode) debugPrint('SupabaseService.initialize() called — deprecated.');
    return;
  }
}
