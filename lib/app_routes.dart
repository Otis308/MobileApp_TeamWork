enum AppScreen {
  login,
  forgotPassword,
  projectSelector,    
  dashboard,
  workOrganization,
  kanbanBoard,
  teamManagement,
  timeline,
  profile,
  notifications,
}

typedef NavigateTo = void Function(AppScreen screen);

const screenLabels = <AppScreen, String>{
  AppScreen.login:           'Đăng nhập & Đăng ký',
  AppScreen.forgotPassword:  'Khôi phục mật khẩu',
  AppScreen.projectSelector: 'Chọn dự án',              
  AppScreen.dashboard:       'Tổng quan',
  AppScreen.workOrganization:'Tổ chức công việc',
  AppScreen.kanbanBoard:     'Bảng Kanban',
  AppScreen.teamManagement:  'Quản lý nhóm',
  AppScreen.timeline:        'Lịch trình',
  AppScreen.profile:         'Profile',
  AppScreen.notifications:   'Thông báo',
};