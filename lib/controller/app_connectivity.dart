import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

enum ConnectionStatus { WiFi, Mobile, Offline }

class ConnectionProvider extends ChangeNotifier {
  ConnectionStatus _status = ConnectionStatus.Offline;

  ConnectionStatus get status => _status;

  void initialize() {
    Connectivity().onConnectivityChanged.listen((result) {
      updateConnectionStatus(result);
    });
  }

  void updateConnectionStatus(ConnectivityResult result) {
    print(result);
    switch (result) {
      case ConnectivityResult.wifi:
        _status = ConnectionStatus.WiFi;
        break;
      case ConnectivityResult.mobile:
        _status = ConnectionStatus.Mobile;
        break;
      case ConnectivityResult.none:
        _status = ConnectionStatus.Offline;
        break;
      default:
        _status = ConnectionStatus.Offline;
        break;
    }
    notifyListeners();
  }
}
