import 'dart:async';
import 'dart:io';

class InternetCheckerService {
  Future<bool> check() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
