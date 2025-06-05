import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class InternetCheckerService {
  Future<bool> check() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.isEmpty || connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }

    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
