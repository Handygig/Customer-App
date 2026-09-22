import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  final Connectivity _connectivity;

  NetworkService({required this._connectivity});

  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();

    if (result.every((e) => e == ConnectivityResult.none)) {
      return false;
    }

    try {
      final lookup = await InternetAddress.lookup('8.8.8.8');
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}
