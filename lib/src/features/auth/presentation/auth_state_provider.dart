import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../utils/dio_client.dart'; // For storageProvider

// 1. Define the possible states
enum AuthState {
  loading,
  authenticated,
  unauthenticated,
}

// 2. Create the Notifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;
  
  AuthStateNotifier(this._storage) : super(AuthState.loading) {
    // Check for token as soon as the app starts
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.unauthenticated;
    }
  }

  // Called by AuthController on successful login
  void onLogin() {
    if (state != AuthState.authenticated) {
      state = AuthState.authenticated;
    }
  }

  // Called by AuthController on logout
  void onLogout() {
    if (state != AuthState.unauthenticated) {
      state = AuthState.unauthenticated;
    }
  }
}

// 3. Create the Provider (This is what your app will watch)
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref.read(storageProvider));
});