import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/workflow_widgets.dart';
import '../../project/presentation/project_provider.dart';
import '../data/models/project_member_model.dart';
import 'team_provider.dart';

class TeamManagementScreen extends ConsumerStatefulWidget {
  const TeamManagementScreen({required this.onNavigate, super.key});
  final NavigateTo onNavigate;

  @override
  ConsumerState<TeamManagementScreen> createState() =>
      _TeamManagementScreenState();
}

class _TeamManagementScreenState
    extends ConsumerState<TeamManagementScreen> {

  String _searchQuery      = '';
  String _selectedRole     = 'Tất cả';
  // Index tab dự án đang chọn (0 = tất cả, 1+ = từng dự án)
  int    _selectedProjectTab = 0;

  // ── Helpers ──
  // Chỉ hiển thị dữ liệu thật từ API (teamState.members) — không còn mock.
  List<ProjectMemberModel> get _activeMembers {
    return ref.read(teamProvider).members;
  }

  // API trả 'role' dạng Admin/Manager/Member → map sang nhãn tiếng Việt.
  // Mô hình mở chỉ dùng Admin/Member; 'Manager' được giữ để hiển thị đúng cho
  // dữ liệu cũ (nếu còn), dù không còn gán được qua giao diện.
  String _accessLabel(ProjectMemberModel m) {
    return switch (m.role) {
      'Admin' => 'Quản trị viên',
      'Manager' => 'Quản lý',
      _ => 'Thành viên',
    };
  }

  List<ProjectMemberModel> get _filteredMembers {
    return _activeMembers.where((m) {
      final name  = m.name.toLowerCase();
      final email = m.email.toLowerCase();
      final access = _accessLabel(m);

      final matchSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase());
      final matchRole = _selectedRole == 'Tất cả' ||
          access == _selectedRole;
      return matchSearch && matchRole;
    }).toList();
  }

  // ── Invite ──
  Future<void> _showInviteDialog() async {
    final emailCtrl = TextEditingController();
    String? errorText;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 12, right: 12,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 12,
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDDD7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.mail_outline_rounded,
                      color: AppColors.accent),
                ),
                const SizedBox(height: 14),
                const Text('Mời thành viên',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('Nhập email để thêm vào dự án đang chọn',
                    style: TextStyle(
                        color: AppColors.muted, fontSize: 11)),
                const SizedBox(height: 20),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'email@congty.com',
                    prefixIcon: const Icon(Icons.mail_outline),
                    errorText: errorText,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    final email = emailCtrl.text.trim();
                    if (email.isEmpty) {
                      setModal(() => errorText = 'Nhập email đi bạn ơi');
                      return;
                    }
                    Navigator.pop(ctx);
                    final error = await ref
                        .read(teamProvider.notifier)
                        .addMember(email);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error ?? 'Đã thêm $email vào dự án'),
                        backgroundColor:
                            error == null ? Colors.green : Colors.red,
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Thêm vào dự án'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Gọi / nhắn: mở ứng dụng gọi điện / nhắn tin mặc định của hệ thống ──
  Future<void> _contactMember(String scheme, String phone) async {
    final number = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final ok = await launchUrl(Uri(scheme: scheme, path: number));
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(scheme == 'tel'
            ? 'Thiết bị này không hỗ trợ gọi điện'
            : 'Thiết bị này không hỗ trợ nhắn tin'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // ── Member detail sheet ──
  void _showMemberDetail(ProjectMemberModel m) {
    final phone = m.phone;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MemberAvatar(
              name:  m.name.isEmpty ? 'U' : m.name,
              color: AppColors.accent,
              size: 72,
              avatarUrl: m.avatarUrl,
            ),
            const SizedBox(height: 12),
            Text(m.name,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              _accessLabel(m),
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              phone.isNotEmpty ? phone : 'Chưa có số điện thoại',
              style: TextStyle(
                color: phone.isNotEmpty
                    ? AppColors.ink
                    : AppColors.soft,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: phone.isNotEmpty
                      ? () {
                          Navigator.pop(sheetContext);
                          _contactMember('tel', phone);
                        }
                      : null,
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: const Text('Gọi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: phone.isNotEmpty
                      ? () {
                          Navigator.pop(sheetContext);
                          _contactMember('sms', phone);
                        }
                      : null,
                  icon: const Icon(Icons.sms_outlined, size: 18),
                  label: const Text('Nhắn'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Menu 3 chấm — chỉ hiện các hành động người dùng thực sự có quyền ──
  void _showMemberMenu(ProjectMemberModel m) {
    final perms = ref.read(teamProvider).permissions;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(m.name,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const Divider(height: 20),
            if (perms.canChangeRoles)
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded,
                    color: AppColors.accent),
                title: const Text('Đổi vai trò'),
                onTap: () {
                  Navigator.pop(context);
                  _showRoleDialog(m);
                },
              ),
            if (perms.canRemove(m))
              ListTile(
                leading: const Icon(Icons.person_remove_outlined,
                    color: Colors.red),
                title: const Text('Xóa khỏi nhóm',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmRemove(m);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showRoleDialog(ProjectMemberModel m) {
    final currentRole = _accessLabel(m);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Đổi vai trò\n${m.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Quản trị viên', 'Thành viên'].map((role) {
            return ListTile(
              title: Text(role),
              trailing: currentRole == role
                  ? const Icon(Icons.check_rounded,
                      color: AppColors.accent)
                  : null,
              onTap: currentRole == role
                  ? null
                  : () async {
                      Navigator.pop(context);
                      final apiRole = switch (role) {
                        'Quản trị viên' => 'Admin',
                        _               => 'Member',
                      };
                      final error = await ref
                          .read(teamProvider.notifier)
                          .updateMemberRole(m.id, apiRole);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error ?? 'Đã đổi sang $role'),
                            backgroundColor:
                                error == null ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _confirmRemove(ProjectMemberModel m) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa thành viên'),
        content: Text('Xóa ${m.name} khỏi nhóm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final error = await ref
                  .read(teamProvider.notifier)
                  .removeMember(m.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(error ?? 'Đã xóa ${m.name}'),
                  backgroundColor: error == null ? Colors.green : Colors.red,
                ));
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
    @override
  Widget build(BuildContext context) {
    // Lấy danh sách dự án từ projectProvider
    final projectState = ref.watch(projectProvider);
    final projects     = projectState.projects;

    final teamState    = ref.watch(teamProvider);
    // Dữ liệu thật từ API — rỗng thì hiển thị empty state (không mock).
    final members      = teamState.members;

    final perms        = teamState.permissions;
    final onlineCount  =
        members.where((m) => teamState.isOnline(m.id)).length;

    final filtered = _filteredMembers;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              ScreenHeader(
                title: 'Đội ngũ',
                eyebrow: '${members.length} THÀNH VIÊN',
                action: perms.canInvite
                    ? FilledButton.icon(
                        onPressed: _showInviteDialog,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Mời'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(88, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),

              // ── TAB CHỌN DỰ ÁN (MỚI) ──
              if (projects.isNotEmpty) ...[
                const Text(
                  'CHỌN DỰ ÁN',
                  style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w800,
                    color: AppColors.muted, letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Tab "Tất cả"
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedProjectTab = 0);
                            ref.read(teamProvider.notifier).loadMembers();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedProjectTab == 0
                                  ? AppColors.accent
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedProjectTab == 0
                                    ? AppColors.accent
                                    : AppColors.line,
                              ),
                            ),
                            child: Text(
                              'Tất cả',
                              style: TextStyle(
                                color: _selectedProjectTab == 0
                                    ? Colors.white
                                    : AppColors.ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Tab từng dự án
                      ...projects.asMap().entries.map((entry) {
                        final i = entry.key + 1;
                        final p = entry.value;
                        final name = p.name;
                        final isSelected = _selectedProjectTab == i;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () async {
                              setState(() => _selectedProjectTab = i);
                              // Load members của project này
                              await ref
                                  .read(teamProvider.notifier)
                                  .loadMembersForProject(
                                    p.id,
                                  );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accent
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.accent
                                      : AppColors.line,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.folder_outlined,
                                      size: 13),
                                  const SizedBox(width: 5),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.ink,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Online counter
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 35, height: 35,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.people_outline,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 9),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$onlineCount',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800)),
                              Text(
                                '/ ${members.length} thành viên',
                                style: const TextStyle(
                                    color: AppColors.soft, fontSize: 8),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),

              // Search
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo tên hoặc email',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Role filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Tất cả', 'Quản trị viên', 'Thành viên']
                      .map((role) {
                    final isSelected = _selectedRole == role;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(role),
                        selected: isSelected,
                        selectedColor: AppColors.accent,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontSize: 11,
                        ),
                        onSelected: (_) =>
                            setState(() => _selectedRole = role),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              const SectionTitle(
                eyebrow: 'CÁC DỰ ÁN',
                title: 'Tất cả thành viên',
              ),
              const SizedBox(height: 13),

              // Danh sách thành viên — giữ nguyên logic cũ
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 13, vertical: 8),
                  child: filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                              child: Text('Không có thành viên nào')),
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < filtered.length; i++) ...[
                              GestureDetector(
                                onTap: () => _showMemberDetail(filtered[i]),
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  child: Row(children: [
                                    Stack(children: [
                                      MemberAvatar(
                                        name: filtered[i].name,
                                        color: AppColors.accent,
                                        size: 44,
                                        avatarUrl: filtered[i].avatarUrl,
                                      ),
                                      Positioned(
                                        right: 0, bottom: 0,
                                        child: Container(
                                          width: 11, height: 11,
                                          decoration: BoxDecoration(
                                            color: teamState.isOnline(filtered[i].id)
                                                ? const Color(0xFF73B88B)
                                                : Colors.grey,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white,
                                                width: 2),
                                          ),
                                        ),
                                      ),
                                    ]),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            filtered[i].name,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w700),
                                          ),
                                          Text(
                                            _accessLabel(filtered[i]),
                                            style: const TextStyle(
                                                color: AppColors.soft,
                                                fontSize: 8),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Badge role
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _accessLabel(filtered[i]) ==
                                                    'Quản trị viên'
                                                ? const Color(0xFFFFDDD7)
                                                : _accessLabel(filtered[i]) ==
                                                        'Quản lý'
                                                    ? Colors.orange.shade50
                                                    : AppColors.background,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _accessLabel(filtered[i]),
                                        style: TextStyle(
                                          color:
                                              _accessLabel(filtered[i]) ==
                                                  'Quản trị viên'
                                              ? AppColors.accentDark
                                              : _accessLabel(filtered[i]) ==
                                                      'Quản lý'
                                                  ? Colors.orange.shade800
                                                  : AppColors.muted,
                                          fontSize: 7,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    // Nút 3 chấm — ẩn nếu không có quyền với thành viên này
                                    if (perms.canManage(filtered[i]))
                                    GestureDetector(
                                      onTap: () =>
                                          _showMemberMenu(filtered[i]),
                                      child: const Padding(
                                        padding: EdgeInsets.all(6),
                                        child: Icon(
                                          Icons.more_vert_rounded,
                                          size: 18,
                                          color: AppColors.soft,
                                        ),
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                              if (i < filtered.length - 1)
                                const Divider(height: 1),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        active:     AppScreen.teamManagement,
        onNavigate: widget.onNavigate,
      ),
    );
  }
}