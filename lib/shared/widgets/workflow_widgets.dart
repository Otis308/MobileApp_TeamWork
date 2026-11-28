import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';

// Nhãn tiếng Việt dùng chung cho trạng thái/độ ưu tiên task — khớp với các bảng
// map cục bộ ở kanban_board_screen.dart/task_detail_screen.dart để nhất quán toàn app.
String vietnameseStatusLabel(String status) => switch (status) {
      'todo' => 'Cần làm',
      'doing' => 'Đang thực hiện',
      'done' => 'Hoàn thành',
      _ => status,
    };

String vietnamesePriorityLabel(String priority) => switch (priority) {
      'high' => 'Cao',
      'medium' => 'Trung bình',
      'low' => 'Thấp',
      _ => priority,
    };

class WorkFlowLogo extends StatelessWidget {
  const WorkFlowLogo({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _bar(-7, 15, -4),
              _bar(0, 21, 4),
              _bar(7, 12, -5),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'TEAMWORK',
          style: TextStyle(
            color: light ? Colors.white : AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
      ],
    );
  }

  Widget _bar(double y, double width, double x) {
    return Transform.translate(
      offset: Offset(x, y),
      child: Transform.rotate(
        angle: -0.14,
        child: Container(
          width: width,
          height: 7,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    required this.title,
    required this.eyebrow,
    super.key,
    this.action,
  });

  final String title;
  final String eyebrow;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(eyebrow),
              const SizedBox(height: 4),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = AppColors.muted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }
}

class CircleAction extends StatelessWidget {
  const CircleAction({
    required this.icon,
    required this.onPressed,
    super.key,
    this.background = Colors.white,
    this.foreground = AppColors.ink,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      color: foreground,
      style: IconButton.styleFrom(
        backgroundColor: background,
        side: const BorderSide(color: AppColors.line),
        fixedSize: const Size(42, 42),
      ),
    );
  }
}

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    required this.name,
    super.key,
    this.color = const Color(0xFFEEB5A7),
    this.size = 36,
    this.avatarUrl = '',
  });

  final String name;
  final Color color;
  final double size;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0])
        .take(2)
        .join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        image: avatarUrl.isEmpty
            ? null
            : DecorationImage(
                image: NetworkImage(AppConfig.resolveUrl(avatarUrl)),
                fit: BoxFit.cover,
                onError: (_, _) {},
              ),
      ),
      child: avatarUrl.isNotEmpty ? null : Text(
        initials,
        style: TextStyle(
          color: AppColors.ink,
          fontSize: size * 0.23,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class AvatarStack extends StatelessWidget {
  // Renders up to [names] real assignee names (from the project members).
  // Empty list → renders nothing (no mock avatars).
  const AvatarStack({super.key, this.names = const []});

  final List<String> names;

  static const _fallbackColors = [
    Color(0xFFEEB5A7),
    AppColors.blue,
    AppColors.yellow,
    AppColors.lilac,
    AppColors.green,
  ];

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();
    final visible = names.take(4).toList();
    return SizedBox(
      width: 28 + 19.0 * (visible.length - 1),
      height: 30,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: 19.0 * i,
              child: MemberAvatar(
                name: visible[i],
                color: _fallbackColors[i % _fallbackColors.length],
                size: 28,
              ),
            ),
        ],
      ),
    );
  }
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.active,
    required this.onNavigate,
    super.key,
  });

  final AppScreen active;
  final NavigateTo onNavigate;

  static const _items = [
    (AppScreen.dashboard, Icons.home_outlined, 'Trang chủ'),
    (AppScreen.workOrganization, Icons.folder_outlined, 'Dự án'),
    (AppScreen.teamManagement, Icons.people_outline, 'Nhóm'),
    (AppScreen.timeline, Icons.calendar_month_outlined, 'Lịch trình'),
    (AppScreen.profile, Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex =
        _items.indexWhere((item) => item.$1 == active).clamp(0, _items.length - 1);
    return NavigationBar(
      height: 70,
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => onNavigate(_items[index].$1),
      indicatorColor: const Color(0xFFFFE0DB),
      backgroundColor: Colors.white,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        for (final item in _items)
          NavigationDestination(icon: Icon(item.$2), label: item.$3),
      ],
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField(this.hint, {this.controller, this.onChanged, super.key});

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    required this.eyebrow,
    required this.title,
    super.key,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(eyebrow),
              const SizedBox(height: 4),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
