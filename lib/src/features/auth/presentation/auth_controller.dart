import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:booklybear/src/features/auth/data/auth_repository.dart';
import 'package:booklybear/src/utils/dio_client.dart';

// 1. State definition (AsyncValue handles Data, Loading, Error automatically)
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  final FlutterSecureStorage _storage;

  AuthController(this._authRepository, this._storage)
      : super(const AsyncValue.data(null));

  Future<bool> login(String email, String password) async {
    // Set state to loading
    state = const AsyncValue.loading();
    
    try {
      // 1. Call API
      final token = await _authRepository.login(email: email, password: password);
      
      // 2. Save Token securely
      await _storage.write(key: 'auth_token', value: token);
      
      // 3. Set state to success
      state = const AsyncValue.data(null);
      return true; // Success
    } catch (e, st) {
      // 4. Set state to error
      state = AsyncValue.error(e, st);
      return false; // Failed
    }
  }

  Future<bool> register(String username, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.register(
        username: username, 
        email: email, 
        password: password
      );
      
      // Note: Your backend doesn't return a token on register, only the user.
      // So the user still needs to login afterwards, or you can auto-login here.
      // For now, we just return success so UI can navigate or ask to login.
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
  
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }
}

// 2. Provider definition
final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    ref.read(authRepositoryProvider),
    ref.read(storageProvider),
  );
});