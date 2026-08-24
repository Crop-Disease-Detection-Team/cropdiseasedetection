import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true) {
    _init();
  }

  final Connectivity _connectivity = Connectivity();

  Future<void> _init() async {
    final dynamic result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    _connectivity.onConnectivityChanged.listen((dynamic result) {
      _updateStatus(result);
    });
  }

  void _updateStatus(dynamic result) {
    if (result is List<ConnectivityResult>) {
      state = result.isNotEmpty && !result.contains(ConnectivityResult.none);
    } else if (result is ConnectivityResult) {
      state = result != ConnectivityResult.none;
    } else {
      state = true;
    }
  }
}
