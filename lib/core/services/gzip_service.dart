import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class GzipService {
  static List<int> compress(String originalData) {
    List<int> original = utf8.encode(originalData);
    List<int> compressed = gzip.encode(original);

    debugPrint('🚀 Original ${original.length} bytes');
    debugPrint('🚀 Compressed ${compressed.length} bytes');

    return compressed;
  }
}
