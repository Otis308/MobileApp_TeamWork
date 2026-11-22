import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository());

final profileProvider = StateNotifierProvider<ProfileController,
    AsyncValue<Map<String, dynamic>>>((ref) {
  return ProfileController(ref.read(profileRepositoryProvider));
});

class ProfileController
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final ProfileRepository _repo;

  ProfileController(this._repo) : super(const AsyncLoading()) {
    // Defer so the provider is fully constructed before state changes
    // (avoids composer-driven resets in widget tests).
    Future.microtask(loadProfile);
  }

  Future<void> loadProfile() async {
    // Only reset to loading if we don't already hold a value — otherwise
    // a refresh would wipe the current profile from the UI.
    if (state is! AsyncData) state = const AsyncLoading();
    try {
      final data = await _repo.getProfile();
      state = AsyncData(data);
    } catch (e) {
      // Surface the real error — the screen already renders an error
      // state with a retry button. No fake default profile.
      state = AsyncError(e, StackTrace.current);
    }
  }

  String _errorText(Object e) => e.toString().replaceFirst('Exception: ', '');

  /// Trả về null khi thành công, ngược lại là thông báo lỗi để hiển thị.
  Future<String?> updateProfile({
    String? fullName,
    String? username,
    String? phone,
    String? birthDate,
    String? gender,
    String? avatarUrl,
  }) async {
    try {
      final updated = await _repo.updateProfile(
        fullName:  fullName,
        username:  username,
        phone:     phone,
        birthDate: birthDate,
        gender:    gender,
        avatarUrl: avatarUrl,
      );
      _merge(updated);
      return null;
    } catch (e) {
      return _errorText(e);
    }
  }

  Future<String?> uploadAvatar(XFile file) async {
    try {
      _merge(await _repo.uploadAvatar(file));
      return null;
    } catch (e) {
      return _errorText(e);
    }
  }

  void _merge(Map<String, dynamic> updated) {
    final current = Map<String, dynamic>.from(state.value ?? {});
    state = AsyncData({...current, ...updated});
  }

  Future<bool> updatePermissions({
    bool? camera,
    bool? contacts,
    bool? messages,
  }) async {
    try {
      await _repo.updatePermissions(
        camera:   camera,
        contacts: contacts,
        messages: messages,
      );
      final current = Map<String, dynamic>.from(state.value ?? {});
      final perms   = Map<String, dynamic>.from(
        current['permissions'] as Map? ?? {},
      );
      if (camera   != null) perms['camera']   = camera;
      if (contacts != null) perms['contacts'] = contacts;
      if (messages != null) perms['messages'] = messages;
      current['permissions'] = perms;
      state = AsyncData(current);
      return true;
    } catch (_) {
      return false;
    }
  }
}