import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token)    => _storage.write(key: 'access_token', value: token);
  Future<String?> getToken()              => _storage.read(key: 'access_token');

  Future<void> saveUserId(String userId)  => _storage.write(key: 'user_id', value: userId);
  Future<String?> getUserId()             => _storage.read(key: 'user_id');

  Future<void> saveProjectId(String id)   => _storage.write(key: 'project_id', value: id);
  Future<String?> getProjectId()          => _storage.read(key: 'project_id');

  Future<void> clearAll()                 => _storage.deleteAll();
}