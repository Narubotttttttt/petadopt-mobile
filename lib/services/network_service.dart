import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_petadopt/services/api_config.dart';

class NetworkService {
  NetworkService._();
  static final NetworkService instance = NetworkService._();

  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isChecking = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isRestored = ValueNotifier<bool>(false);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _restoredTimer;
  Timer? _heartbeatTimer;
  bool _hasEverBeenOffline = false;
  bool _isInitialized = false;

  /// Initialize real-time network monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      // Check initial connectivity
      await checkConnection();

      // Listen for physical network interface changes
      _subscription = _connectivity.onConnectivityChanged.listen((results) async {
        await _handleConnectivityChange(results);
      });

      // Heartbeat probe every 20 seconds to detect WAN drop on active Wi-Fi/cellular
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        if (!isChecking.value) {
          _silentProbe();
        }
      });
    } catch (e) {
      debugPrint('NetworkService init error: $e');
    }
  }

  /// Manually trigger a connectivity check with active status
  Future<bool> checkConnection() async {
    isChecking.value = true;
    try {
      final results = await _connectivity.checkConnectivity();
      final hasInterface = results.isNotEmpty && !results.every((r) => r == ConnectivityResult.none);

      if (!hasInterface) {
        _setOffline();
        isChecking.value = false;
        return false;
      }

      final reachable = await _probeInternetReachability();
      if (reachable) {
        _setOnline();
        isChecking.value = false;
        return true;
      } else {
        _setOffline();
        isChecking.value = false;
        return false;
      }
    } catch (_) {
      final reachable = await _probeInternetReachability();
      if (reachable) {
        _setOnline();
        isChecking.value = false;
        return true;
      } else {
        _setOffline();
        isChecking.value = false;
        return false;
      }
    }
  }

  /// Silent background reachability probe
  Future<void> _silentProbe() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasInterface = results.isNotEmpty && !results.every((r) => r == ConnectivityResult.none);
      if (!hasInterface) {
        _setOffline();
        return;
      }

      final reachable = await _probeInternetReachability();
      if (reachable) {
        _setOnline();
      } else {
        _setOffline();
      }
    } catch (_) {}
  }

  /// Low-level DNS reachability check
  Future<bool> _probeInternetReachability() async {
    try {
      // Target host from ApiConfig (either production host or google.com fallback)
      final host = Uri.tryParse(ApiConfig.baseUrl)?.host ?? 'google.com';
      final lookupTarget = (host.isNotEmpty && !host.contains('127.0.0.1') && !host.contains('localhost'))
          ? host
          : 'google.com';

      final result = await InternetAddress.lookup(lookupTarget)
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Called whenever an API call fails with SocketException / TimeoutException
  void notifyConnectionLost() {
    _setOffline();
  }

  /// Called whenever an API call succeeds
  void notifyRequestSuccess() {
    if (!isConnected.value) {
      _setOnline();
    }
  }

  void _setOffline() {
    if (isConnected.value) {
      _hasEverBeenOffline = true;
      isRestored.value = false;
      isConnected.value = false;
    }
  }

  void _setOnline() {
    if (!isConnected.value) {
      isConnected.value = true;
      if (_hasEverBeenOffline) {
        isRestored.value = true;
        _restoredTimer?.cancel();
        _restoredTimer = Timer(const Duration(seconds: 3), () {
          isRestored.value = false;
        });
      }
    }
  }

  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    final hasInterface = results.isNotEmpty && !results.every((r) => r == ConnectivityResult.none);
    if (!hasInterface) {
      _setOffline();
    } else {
      await checkConnection();
    }
  }

  void dispose() {
    _subscription?.cancel();
    _restoredTimer?.cancel();
    _heartbeatTimer?.cancel();
  }
}

