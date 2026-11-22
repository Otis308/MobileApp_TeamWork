import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app_routes.dart';
import 'auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({required this.onNavigate, super.key});
  final NavigateTo onNavigate;

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  int _currentStep = 1; // 1: Nhập Email | 2: Nhập OTP | 3: Đổi mật khẩu
  String _savedEmail = '';
  
  // Controllers
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Timer 60s
  int _secondsLeft = 60;
  Timer? _timer;

  // Màu sắc chủ đạo từ thiết kế
  final Color _primaryOrange = const Color(0xFFFF5C00);

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _secondsLeft = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleRequestOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return _showError('Vui lòng nhập Email');

    final success = await ref.read(authControllerProvider.notifier).requestReset(email);
    if (success && mounted) {
      setState(() {
        _savedEmail = email;
        _currentStep = 2;
      });
      _startTimer();
    } else if (mounted) {
      final error = ref.read(authControllerProvider).error.toString();
      _showError(error.contains('Exception: ') ? error.split('Exception: ')[1] : error);
    }
  }

  Future<void> _handleVerifyAndReset() async {
    final otp = _otpController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (_currentStep == 2) {
      if (otp.isEmpty || otp.length < 6) return _showError('Vui lòng nhập đủ 6 số OTP');
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      if (newPass != confirmPass) return _showError('Mật khẩu xác nhận không khớp');
      if (newPass.length < 6) return _showError('Mật khẩu phải từ 6 ký tự');

      final success = await ref.read(authControllerProvider.notifier)
          .confirmReset(_savedEmail, otp, newPass);
          
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đổi mật khẩu thành công! Vui lòng đăng nhập.'), backgroundColor: Colors.green),
        );
        widget.onNavigate(AppScreen.login);
      } else if (mounted) {
        final rawError = ref.read(authControllerProvider).error.toString();
        final errorMsg = rawError.contains('Exception: ')
            ? rawError.split('Exception: ')[1]
            : rawError;

        // Server từ chối OTP (không hợp lệ hoặc hết hạn) -> Tự động quay lại bước 2 để nhập/gửi lại mã
        setState(() {
          _currentStep = 2;
          _otpController.clear();
        });
        _showError(errorMsg);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  // --- WIDGETS GIAO DIỆN CHUẨN DESIGN ---

  Widget _buildTopGraphic(IconData icon) {
    return Center(
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Center(
          child: Container(
            width: 95,
            height: 95,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _primaryOrange,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryOrange.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomOtpInput() {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            String digit = '';
            if (_otpController.text.length > index) {
              digit = _otpController.text[index];
            }
            return Container(
              width: 48,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                digit,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            );
          }),
        ),
        Positioned.fill(
          child: TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            cursorColor: Colors.transparent,
            style: const TextStyle(color: Colors.transparent),
            decoration: const InputDecoration(
              counterText: '',
              filled: false,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
            onChanged: (val) => setState(() {}),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AsyncLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              if (_currentStep > 1) {
                setState(() => _currentStep--);
              } else {
                widget.onNavigate(AppScreen.login);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // GRAPHIC ĐẦU TRANG THEO TỪNG BƯỚC
            if (_currentStep == 1) _buildTopGraphic(Icons.search_rounded),
            if (_currentStep == 2) _buildTopGraphic(Icons.mail_outline_rounded),
            if (_currentStep == 3) _buildTopGraphic(Icons.lock_outline_rounded),
            
            const SizedBox(height: 40),
            
            // EYEBROW TEXT
            Text(
              _currentStep == 1 ? 'KHÔI PHỤC TÀI KHOẢN' 
            : _currentStep == 2 ? 'KIỂM TRA HỘP THƯ' 
            : 'BẢO MẬT',
              style: TextStyle(
                color: _primaryOrange, 
                fontSize: 11, 
                fontWeight: FontWeight.w700, 
                letterSpacing: 1.2
              ),
            ),
            const SizedBox(height: 8),
            
            // TIÊU ĐỀ LỚN
            Text(
              _currentStep == 1 ? 'Quên mật khẩu?' 
            : _currentStep == 2 ? 'Nhập mã xác minh' 
            : 'Tạo mật khẩu mới',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // BƯỚC 1: NHẬP EMAIL
            if (_currentStep == 1) ...[
              Text(
                'Nhập email của bạn, chúng tôi sẽ gửi mã gồm 6 chữ số để đặt lại mật khẩu.',
                style: TextStyle(color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Email của bạn',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: isLoading ? null : _handleRequestOtp,
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryOrange,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Gửi mã', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],

            // BƯỚC 2: NHẬP OTP (Chuẩn thiết kế)
            if (_currentStep == 2) ...[
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.grey.shade600, height: 1.5, fontSize: 14),
                  children: [
                    const TextSpan(text: 'Chúng tôi đã gửi mã gồm 6 chữ số đến '),
                    TextSpan(text: _savedEmail, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    const TextSpan(text: '. Mã sẽ hết hạn sau 60 giây.'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildCustomOtpInput(),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: (_secondsLeft > 0 && !isLoading) ? _handleVerifyAndReset : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryOrange,
                  disabledBackgroundColor: _primaryOrange.withValues(alpha: 0.5),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check, size: 20),
                    SizedBox(width: 8),
                    Text('Xác minh mã', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: (_secondsLeft == 0 && !isLoading) ? _handleRequestOtp : null,
                  child: Text(
                    _secondsLeft > 0 ? 'Chưa nhận được mã? Gửi lại sau 00:${_secondsLeft.toString().padLeft(2, '0')}' : 'Chưa nhận được mã? Gửi lại',
                    style: TextStyle(
                      color: _secondsLeft > 0 ? Colors.grey.shade600 : _primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

            // BƯỚC 3: ĐẶT MẬT KHẨU MỚI
            if (_currentStep == 3) ...[
              Text(
                'Nhập mật khẩu mới cho tài khoản của bạn.',
                style: TextStyle(color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Mật khẩu mới',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Xác nhận mật khẩu',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: isLoading ? null : _handleVerifyAndReset,
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryOrange,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Xác nhận & Đổi mật khẩu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}