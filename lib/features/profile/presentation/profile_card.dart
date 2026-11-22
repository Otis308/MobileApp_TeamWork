import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import 'profile_provider.dart';

const genderLabels = {'male': 'Nam', 'female': 'Nữ', 'other': 'Khác'};

/// 'YYYY-MM-DD' → 'DD/MM/YYYY' (rỗng nếu chưa có).
String formatBirthDate(String iso) {
  final p = iso.split('-');
  if (p.length != 3) return '';
  return '${p[2]}/${p[1]}/${p[0]}';
}

String _initials(String name) {
  final w = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
  if (w.isEmpty) return '?';
  if (w.length == 1) return w[0][0].toUpperCase();
  return '${w.first[0]}${w.last[0]}'.toUpperCase();
}

/// Thẻ định danh (ảnh, tên, email, nút sửa) + các ô thông tin cá nhân.
/// Nút "Chỉnh sửa thông tin" chuyển các ô sang dạng nhập liệu; bấm "Lưu thông tin mới"
/// sẽ gửi PATCH /users/me và cập nhật vào database.
class ProfileCard extends ConsumerStatefulWidget {
  const ProfileCard({required this.profile, super.key});
  final Map<String, dynamic> profile;

  @override
  ConsumerState<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<ProfileCard> {
  bool _editing = false;
  bool _saving = false;
  bool _uploading = false;
  final _usernameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _birthDate = '';
  String _gender = '';

  Map<String, dynamic> get _profile =>
      ref.read(profileProvider).value ?? widget.profile;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _startEditing() {
    final p = _profile;
    _usernameCtrl.text = p['username'] as String? ?? '';
    _nameCtrl.text = p['fullName'] as String? ?? '';
    _phoneCtrl.text = p['phone'] as String? ?? '';
    _birthDate = p['birthDate'] as String? ?? '';
    _gender = p['gender'] as String? ?? '';
    setState(() => _editing = true);
  }

  void _toast(String text, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _toast('Họ và tên không được để trống', ok: false);
      return;
    }
    setState(() => _saving = true);
    final error = await ref.read(profileProvider.notifier).updateProfile(
          fullName: _nameCtrl.text.trim(),
          username: _usernameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          birthDate: _birthDate,
          gender: _gender,
        );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (error == null) _editing = false;
    });
    _toast(error ?? 'Đã cập nhật thông tin', ok: error == null);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(_birthDate) ?? DateTime(now.year - 20);
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isAfter(now) ? now : current,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Chọn ngày sinh',
    );
    if (picked == null) return;
    String two(int n) => n.toString().padLeft(2, '0');
    setState(() => _birthDate = '${picked.year}-${two(picked.month)}-${two(picked.day)}');
  }

  // ── Ảnh đại diện ──
  Future<void> _pickAvatar(ImageSource source) async {
    if (source == ImageSource.camera && !kIsWeb) {
      var status = await Permission.camera.status;
      if (!status.isGranted) status = await Permission.camera.request();
      if (!status.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Bạn chưa cấp quyền Camera nên chưa thể chụp ảnh'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Mở cài đặt',
            textColor: Colors.white,
            onPressed: openAppSettings,
          ),
        ));
        return;
      }
      ref.read(profileProvider.notifier).updatePermissions(camera: true);
    }

    XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
    } catch (_) {
      _toast(
        source == ImageSource.camera
            ? 'Không mở được camera trên thiết bị này'
            : 'Không mở được thư viện ảnh',
        ok: false,
      );
      return;
    }
    if (file == null || !mounted) return;

    setState(() => _uploading = true);
    final error = await ref.read(profileProvider.notifier).uploadAvatar(file);
    if (!mounted) return;
    setState(() => _uploading = false);
    _toast(error ?? 'Đã cập nhật ảnh đại diện', ok: error == null);
  }

  void _showAvatarSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Thay ảnh đại diện',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh'),
              subtitle: const Text('Cần cấp quyền Camera',
                  style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn ảnh từ thư viện / tệp'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAvatar(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value ?? widget.profile;
    final name = profile['fullName'] as String? ?? '';
    final email = profile['email'] as String? ?? '';
    final avatarUrl = profile['avatarUrl'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              children: [
                _Avatar(
                  name: name,
                  avatarUrl: avatarUrl,
                  busy: _uploading,
                  onCameraTap: _uploading ? null : _showAvatarSheet,
                ),
                const SizedBox(height: 16),
                Text(name.isNotEmpty ? name : 'Chưa có tên',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(email,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 18),
                if (!_editing)
                  FilledButton.icon(
                    onPressed: _startEditing,
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: const Text('Chỉnh sửa thông tin'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(190, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                  )
                else
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _saving ? null : () => setState(() => _editing = false),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_outlined, size: 17),
                        label: const Text('Lưu thông tin mới'),
                      ),
                    ),
                  ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _editing ? _editTiles(email) : _viewTiles(profile),
      ],
    );
  }

  // ── Chế độ xem ──
  Widget _viewTiles(Map<String, dynamic> p) {
    String v(String key) => (p[key] as String? ?? '');
    final birth = formatBirthDate(v('birthDate'));
    return Column(children: [
      InfoTile(
          icon: Icons.alternate_email_rounded,
          label: 'Username',
          value: v('username').isEmpty ? '' : '@${v('username')}'),
      InfoTile(icon: Icons.person_outline, label: 'Họ và tên', value: v('fullName')),
      InfoTile(icon: Icons.mail_outline, label: 'Email', value: v('email')),
      InfoTile(icon: Icons.cake_outlined, label: 'Ngày sinh', value: birth),
      InfoTile(
          icon: Icons.wc_rounded,
          label: 'Giới tính',
          value: genderLabels[v('gender')] ?? ''),
      InfoTile(icon: Icons.phone_outlined, label: 'Số điện thoại', value: v('phone')),
    ]);
  }

  // ── Chế độ chỉnh sửa ──
  Widget _editTiles(String email) {
    return Column(children: [
      _EditTile(
        child: TextField(
          controller: _usernameCtrl,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Username',
            helperText: '3-30 ký tự: chữ, số, _ hoặc .',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
        ),
      ),
      _EditTile(
        child: TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Họ và tên',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
      ),
      _EditTile(
        child: TextField(
          readOnly: true,
          controller: TextEditingController(text: email),
          decoration: const InputDecoration(
            labelText: 'Email (không thể đổi)',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
      ),
      _EditTile(
        child: InkWell(
          onTap: _pickBirthDate,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Ngày sinh',
              prefixIcon: const Icon(Icons.cake_outlined),
              suffixIcon: _birthDate.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() => _birthDate = ''),
                    ),
            ),
            child: Text(
              _birthDate.isEmpty ? 'Chọn ngày sinh' : formatBirthDate(_birthDate),
              style: TextStyle(
                color: _birthDate.isEmpty ? AppColors.soft : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
      _EditTile(
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Giới tính',
            prefixIcon: Icon(Icons.wc_rounded),
          ),
          child: Wrap(
            spacing: 8,
            children: [
              for (final e in genderLabels.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: _gender == e.key,
                  onSelected: (sel) => setState(() => _gender = sel ? e.key : ''),
                ),
            ],
          ),
        ),
      ),
      _EditTile(
        child: TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Số điện thoại',
            helperText: 'Thành viên cùng dự án sẽ thấy số này để gọi/nhắn',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
      ),
    ]);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.avatarUrl,
    required this.busy,
    required this.onCameraTap,
  });
  final String name, avatarUrl;
  final bool busy;
  final VoidCallback? onCameraTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 94,
          height: 94,
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFEEB5A7),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x18000000), blurRadius: 18, offset: Offset(0, 8)),
            ],
            image: avatarUrl.isEmpty
                ? null
                : DecorationImage(
                    image: NetworkImage(AppConfig.resolveUrl(avatarUrl)),
                    fit: BoxFit.cover,
                    onError: (_, _) {},
                  ),
          ),
          child: busy
              ? const CircularProgressIndicator(strokeWidth: 3)
              : avatarUrl.isNotEmpty
                  ? null
                  : Text(
                      _initials(name),
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
        ),
        Positioned(
          right: -2,
          bottom: 2,
          child: GestureDetector(
            onTap: onCameraTap,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.camera_alt_outlined,
                  color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

/// Một ô thông tin cá nhân (chế độ xem).
class InfoTile extends StatelessWidget {
  const InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final empty = value.isEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(children: [
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.accent, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10)),
              const SizedBox(height: 2),
              Text(
                empty ? 'Chưa cập nhật' : value,
                style: TextStyle(
                  color: empty ? AppColors.soft : AppColors.ink,
                  fontSize: 14,
                  fontWeight: empty ? FontWeight.w400 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _EditTile extends StatelessWidget {
  const _EditTile({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 10), child: child);
}
