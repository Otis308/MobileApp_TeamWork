import 'package:flutter_riverpod/legacy.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/core_providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

// Nguồn sự thật duy nhất cho "đã đăng nhập chưa" — router dùng để chặn route.
class AuthStatusNotifier extends StateNotifier<AuthStatus> {
  final Future<String?> Function() _readToken;

  AuthStatusNotifier(this._readToken) : super(AuthStatus.unknown) {
    _restore();
  }

  Future<void> _restore() async {
    final token = await _readToken();
    state = (token != null && token.isNotEmpty)
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
  }

  void setAuthenticated() => state = AuthStatus.authenticated;
  void setUnauthenticated() => state = AuthStatus.unauthenticated;
}

final authStatusProvider =
    StateNotifierProvider<AuthStatusNotifier, AuthStatus>((ref) {
  final session = ref.read(sessionServiceProvider);
  final notifier = AuthStatusNotifier(session.getToken);
  ApiClient.onUnauthorized = () {
    notifier.setUnauthenticated();
  };
  return notifier;
});
