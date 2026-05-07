import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

enum ConnectionStatus { WiFi, Mobile, Offline }

class ConnectionProvider extends ChangeNotifier {
  ConnectionStatus _status = ConnectionStatus.Offline;

  ConnectionStatus get status => _status;

  void initialize() {
    Connectivity().onConnectivityChanged.listen((results) {
      updateConnectionStatus(results);
    });
  }

  void updateConnectionStatus(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) {
      _status = ConnectionStatus.WiFi;
    }
    else if (results.contains(ConnectivityResult.mobile)) {
      _status = ConnectionStatus.Mobile;
    }
    else {
      _status = ConnectionStatus.Offline;
    }
    notifyListeners();
  }
}
