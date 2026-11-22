import 'dart:async';

class InAppNotification {
  final String title;
  final String body;
  final String type;
  final String? projectId;
  final String? taskId;

  const InAppNotification({
    required this.title,
    required this.body,
    required this.type,
    this.projectId,
    this.taskId,
  });
}

class InAppNotificationService {
  static final InAppNotificationService _instance =
      InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();

  final StreamController<InAppNotification> _controller =
      StreamController<InAppNotification>.broadcast();

  Stream<InAppNotification> get stream => _controller.stream;

  void push({
    required String title,
    required String body,
    required String type,
    String? projectId,
    String? taskId,
  }) {
    if (!_controller.isClosed) {
      _controller.add(
        InAppNotification(
          title: title,
          body: body,
          type: type,
          projectId: projectId,
          taskId: taskId,
        ),
      );
    }
  }
}
