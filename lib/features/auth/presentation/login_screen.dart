import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/workflow_widgets.dart';
import 'auth_provider.dart'; 

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({required this.onNavigate, super.key});

  final NavigateTo onNavigate;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLogin = true;
  bool _showPassword = false;

  // 2. Khai báo các bộ điều khiển để lấy chữ từ ô nhập liệu
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Hàm xử lý logic khi bấm nút Đăng nhập / Đăng ký
  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    // Kiểm tra rỗng
    if (email.isEmpty || password.isEmpty || (!_isLogin && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    if (_isLogin) {
      // GỌI API ĐĂNG NHẬP
      final success = await ref.read(authControllerProvider.notifier).login(email, password);
      if (success && mounted) {
        // Đăng nhập thành công -> Chuyển sang Dashboard
        widget.onNavigate(AppScreen.dashboard);
      } else if (mounted) {
        // Đăng nhập thất bại -> Báo lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thất bại. Vui lòng kiểm tra lại!')),
        );
      }
      } else {
      // GỌI API ĐĂNG KÝ — tài khoản dùng được ngay (server đã cấp token)
      final success = await ref.read(authControllerProvider.notifier).register(name, email, password);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thành công!')),
        );
        // Vào thẳng trang chủ; user mới chưa có dự án sẽ thấy thẻ "chọn dự án" ở đó
        widget.onNavigate(AppScreen.dashboard);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thất bại. Email có thể đã tồn tại!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theo dõi trạng thái API (để biết lúc nào đang xoay loading)
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AsyncLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WorkFlowLogo(),
              const SizedBox(height: 48),
              const Eyebrow('CÙNG NHÓM, CÙNG TIẾN.', color: AppColors.accent),
              const SizedBox(height: 12),
              Text(
                _isLogin ? 'Chào mừng trở lại.' : 'Tạo dự án.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? 'Tiếp tục công việc cùng đội ngũ của bạn.'
                    : 'Biến công việc bận rộn thành tiến độ rõ ràng.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 30),
              _AuthSwitcher(
                isLogin: _isLogin,
                onChanged: (value) => setState(() => _isLogin = value),
              ),
              const SizedBox(height: 22),
              if (!_isLogin) ...[
                const _FieldLabel('Họ và tên'),
                TextField(
                  controller: _nameController, // Gắn controller
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    hintText: 'Nhập họ và tên',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const _FieldLabel('Email'),
              TextField(
                controller: _emailController, // Gắn controller
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  hintText: 'ten@gmail.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Mật khẩu'),
              TextField(
                controller: _passwordController, // Gắn controller
                obscureText: !_showPassword,
                autofillHints: [
                  _isLogin ? AutofillHints.password : AutofillHints.newPassword,
                ],
                decoration: InputDecoration(
                  hintText: 'Nhập mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: 'Hiển thị mật khẩu',
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              if (_isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading ? null : () => widget.onNavigate(AppScreen.forgotPassword),
                    child: const Text('Quên mật khẩu?'),
                  ),
                )
              else
                const SizedBox(height: 20),
              
              // Nút bấm có trạng thái Loading
              FilledButton(
                onPressed: isLoading ? null : _submit, // Khóa nút khi đang load
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_isLogin ? 'Đăng nhập TeamWork' : 'Tạo tài khoản'),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 19),
                        ],
                      ),
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'Khi tiếp tục, bạn đồng ý với Điều khoản và\nChính sách bảo mật của chúng tôi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.soft, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Giữ nguyên _AuthSwitcher và _FieldLabel ở dưới...
class _AuthSwitcher extends StatelessWidget {
  const _AuthSwitcher({required this.isLogin, required this.onChanged});

  final bool isLogin;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _tab('Đăng nhập', isLogin, () => onChanged(true)),
          _tab('Đăng ký', !isLogin, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _tab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: selected ? AppColors.ink : AppColors.muted,
          backgroundColor: selected ? Colors.white : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 7),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}