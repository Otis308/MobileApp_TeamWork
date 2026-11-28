import {
  Controller, Get, Post, Patch, Delete,
  Param, Body, Query, UseGuards,
} from '@nestjs/common';
import { TasksService } from './tasks.service';
import { CreateTaskDto, UpdateTaskDto, MoveTaskDto } from './dto/task.dto';
import { CreateCommentDto } from './dto/create-comment.dto';
import { GetTasksQueryDto } from './dto/get-tasks-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('tasks')
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  @Get('project/:projectId')
  getProjectTasks(
    @Param('projectId') projectId: string,
    @CurrentUser('userId') userId: string,
    @Query() query: GetTasksQueryDto,
  ) {
    return this.tasksService.getProjectTasks(projectId, userId, query);
  }

  @Get('project/:projectId/progress')
  getProgress(
    @Param('projectId') projectId: string,
    @CurrentUser('userId') userId: string,
  ) {
    return this.tasksService.getProjectProgress(projectId, userId);
  }

  @Post()
  createTask(@CurrentUser('userId') userId: string, @Body() dto: CreateTaskDto) {
    return this.tasksService.createTask(dto, userId);
  }

  @Patch(':id')
  updateTask(
    @Param('id') taskId: string,
    @Body() dto: UpdateTaskDto,
    @CurrentUser('userId') userId: string,
  ) {
    return this.tasksService.updateTask(taskId, dto, userId);
  }

  @Patch(':id/move')
  moveTask(
    @Param('id') taskId: string,
    @Body() dto: MoveTaskDto,
    @CurrentUser('userId') userId: string,
  ) {
    return this.tasksService.moveTask(taskId, dto, userId);
  }

  @Delete(':id')
  deleteTask(@Param('id') taskId: string, @CurrentUser('userId') userId: string) {
    return this.tasksService.deleteTask(taskId, userId);
  }

  @Get(':id/comments')
  getComments(@Param('id') taskId: string, @CurrentUser('userId') userId: string) {
    return this.tasksService.getComments(taskId, userId);
  }

  @Post(':id/comments')
  addComment(
    @Param('id') taskId: string,
    @Body() dto: CreateCommentDto,
    @CurrentUser('userId') userId: string,
  ) {
    return this.tasksService.addComment(taskId, dto, userId);
  }

  @Delete(':id/comments/:commentId')
  deleteComment(
    @Param('id') taskId: string,
    @Param('commentId') commentId: string,
    @CurrentUser('userId') userId: string,
  ) {
    return this.tasksService.deleteComment(taskId, commentId, userId);
  }
}
