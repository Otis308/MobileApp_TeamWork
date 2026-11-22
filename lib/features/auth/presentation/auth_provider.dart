import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/auth_repository.dart';
import '../../../core/services/session_service.dart'; 
import '../../../core/services/websocket_service.dart';
import '../../../core/providers/core_providers.dart';
import 'auth_status_provider.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    ref.read(authRepositoryProvider),
    ref.read(sessionServiceProvider),
    ref.read(webSocketServiceProvider),
    ref.read(authStatusProvider.notifier),
  );
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;
  final SessionService _session;
  final WebSocketService _ws;
  final AuthStatusNotifier _authStatus;

  AuthController(this._repository, this._session, this._ws, this._authStatus)
      : super(const AsyncData(null));

  Future<bool> login(String email, String password) async {
    state = const AsyncLoading(); // Kích hoạt UI xoay vòng loading
    try {
      final data = await _repository.login(email, password);

      await _session.saveToken(data['access_token'] as String);
      
      final user = data['user'] as Map<String, dynamic>?;
      if (user != null) {
        await _session.saveUserId(user['sub'].toString());
      }

      await _ws.connect();
      _authStatus.setAuthenticated();

      state = const AsyncData(null);
      return true; // Thành công
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false; // Thất bại
    }
  }

  Future<bool> register(String fullName, String email, String password) async {
    state = const AsyncLoading();
    try {
      final data = await _repository.register(fullName, email, password);

      // Server returns a token on register — save it immediately so the
      // new account is usable without a separate login round-trip.
      final token = data['access_token'] as String?;
      if (token != null) {
        await _session.saveToken(token);
        final user = data['user'] as Map<String, dynamic>?;
        if (user != null) {
          await _session.saveUserId(user['sub'].toString());
        }
        await _ws.connect();
        _authStatus.setAuthenticated();
      }

      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> requestReset(String email) async {
    state = const AsyncLoading();
    try {
      await _repository.requestPasswordReset(email);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> confirmReset(String email, String otp, String newPassword) async {
    state = const AsyncLoading();
    try {
      await _repository.confirmResetPassword(email, otp, newPassword);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
  
  Future<void> logout() async {
    _ws.disconnect(); 
    await _session.clearAll();
    _authStatus.setUnauthenticated();
    state = const AsyncData(null);
  }
}