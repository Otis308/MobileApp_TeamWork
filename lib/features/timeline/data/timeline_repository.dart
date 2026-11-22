import '../../task_board/data/models/task_model.dart';
import '../../task_board/data/task_repository.dart';

// Lọc theo ngày/quá hạn do server làm (GET /tasks/project/:id?dueAfter&dueBefore&overdue).
class TimelineRepository {
  final TaskRepository _tasks;
  TimelineRepository([TaskRepository? tasks]) : _tasks = tasks ?? TaskRepository();

  List<TaskModel> _flatten(
    ({List<TaskModel> todo, List<TaskModel> doing, List<TaskModel> done}) b,
  ) =>
      [...b.todo, ...b.doing, ...b.done];

  // Task có hạn trong [fromUtc, toExclusiveUtc).
  Future<List<TaskModel>> dueBetween(
    String projectId,
    DateTime fromUtc,
    DateTime toExclusiveUtc,
  ) async {
    final board = await _tasks.getBoard(
      projectId,
      // Nới ±1 ngày vì task có giờ được xếp theo ngày địa phương; provider lọc lại theo ngày.
      dueAfter: fromUtc.subtract(const Duration(days: 1)),
      dueBefore: toExclusiveUtc.add(const Duration(days: 1)),
    );
    return _flatten(board);
  }

  // Task chưa xong và đã quá hạn, hạn cũ nhất lên đầu.
  Future<List<TaskModel>> overdue(String projectId) async {
    final board = await _tasks.getBoard(projectId, overdue: true);
    return _flatten(board)
      ..sort((a, b) =>
          (a.dueDate ?? DateTime(2100)).compareTo(b.dueDate ?? DateTime(2100)));
  }
}
