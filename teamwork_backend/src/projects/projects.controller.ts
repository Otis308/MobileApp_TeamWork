import {
  Controller, Get, Post, Delete, Patch,
  Param, Body, UseGuards,
} from '@nestjs/common';
import { ProjectsService } from './projects.service';
import { CreateProjectDto, UpdateProjectDto } from './dto/create-project.dto';
import { AddMemberDto } from './dto/add-member.dto';
import { UpdateMemberRoleDto } from './dto/update-member-role.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('projects')
export class ProjectsController {
  constructor(private readonly projectsService: ProjectsService) {}

  // GET /projects/mine — danh sách dự án của user
  @Get('mine')
  getMyProjects(@CurrentUser('userId') userId: string) {
    return this.projectsService.getMyProjects(userId);
  }

  // POST /projects — tạo dự án mới
  @Post()
  createProject(
    @CurrentUser('userId') userId: string,
    @Body() dto: CreateProjectDto,
  ) {
    return this.projectsService.createProject(dto, userId);
  }

  @Get(':id/members')
  getMembers(
    @Param('id') projectId: string,
    @CurrentUser('userId') userId: string,
  ) {
    return this.projectsService.getProjectMembers(projectId, userId);
  }

  // Vai trò hiệu lực của chính người gọi trong dự án (owner = Admin).
  @Get(':id/members/me/role')
  getMyRole(
    @Param('id') projectId: string,
    @CurrentUser('userId') userId: string,
  ) {
    return this.projectsService.getMyRole(projectId, userId);
  }

  @Roles('Admin', 'Manager')
  @Post(':id/members')
  addMember(
    @Param('id') projectId: string,
    @Body() dto: AddMemberDto,
    @CurrentUser('userId') userId: string,
  ) {
    return this.projectsService.addMemberByEmail(projectId, dto.email, userId);
  }

  // Rule chi tiết "Manager không xoá được Admin/Manager" nằm trong service.
  @Delete(':id/members/:userId')
  removeMember(
    @Param('id') projectId: string,
    @Param('userId') targetUserId: string,
    @CurrentUser('userId') userId: string,
  ) {
    return this.projectsService.removeMember(projectId, targetUserId, userId);
  }

  @Roles('Admin')
  @Patch(':id/members/:userId/role')
  updateMemberRole(
    @Param('id') projectId: string,
    @Param('userId') targetUserId: string,
    @Body() dto: UpdateMemberRoleDto,
    @CurrentUser('userId') userId: string,
  ) {
    return this.projectsService.updateMemberRole(
      projectId, targetUserId, dto.role, userId,
    );
  }

  @Roles('Admin')
  @Patch(':id')
  updateProject(
    @Param('id') projectId: string,
    @Body() dto: UpdateProjectDto,
    @CurrentUser('userId') userId: string,
  ) {
    return this.projectsService.updateProject(projectId, dto, userId);
  }

  @Roles('Admin')
  @Delete(':id')
  deleteProject(
    @Param('id') projectId: string,
    @CurrentUser('userId') userId: string,
  ) {
    return this.projectsService.deleteProject(projectId, userId);
  }
}
