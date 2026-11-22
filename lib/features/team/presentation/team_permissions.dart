import '../data/models/project_member_model.dart';

// Phản chiếu luật phân quyền của server (để ẩn nút người dùng không có quyền bấm).
// Server vẫn là nơi thực thi cuối cùng — đây chỉ là gating giao diện.
class TeamPermissions {
  final String? myRole;
  const TeamPermissions(this.myRole);

  bool get isAdmin => myRole == 'Admin';
  bool get isManager => myRole == 'Manager';

  bool get canInvite => isAdmin || isManager;
  bool get canChangeRoles => isAdmin;

  // Quản lý chỉ được xóa Thành viên; Quản trị xóa được mọi người.
  bool canRemove(ProjectMemberModel target) =>
      isAdmin || (isManager && target.role == 'Member');

  bool canManage(ProjectMemberModel target) =>
      canChangeRoles || canRemove(target);
}
