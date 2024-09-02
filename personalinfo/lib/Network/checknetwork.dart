import 'package:connectivity_plus/connectivity_plus.dart';

class Network {
  static Future<bool> checkInternetConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}
