import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Project } from '../../projects/schemas/project.schema';
import { ProjectMember } from '../../projects/schemas/project-member.schema';

export type ProjectRole = 'Admin' | 'Manager' | 'Member';

@Injectable()
export class ProjectAccessService {
  constructor(
    @InjectModel(Project.name) private projectModel: Model<Project>,
    @InjectModel(ProjectMember.name) private projectMemberModel: Model<ProjectMember>,
  ) {}

  // ownerId là nguồn chân lý: chủ dự án luôn là Admin dù thiếu ProjectMember.
  async getEffectiveRole(projectId: string, userId: string): Promise<ProjectRole | null> {
    const project = await this.projectModel.findById(projectId);
    if (!project) return null;
    if (project.ownerId.toString() === userId) return 'Admin';
    const member = await this.projectMemberModel.findOne({ projectId, userId });
    return (member?.role as ProjectRole | undefined) ?? null;
  }

  async assertIsMember(projectId: string, userId: string) {
    const project = await this.projectModel.findById(projectId);
    if (!project) throw new NotFoundException('Không tìm thấy dự án');
    if (project.ownerId.toString() === userId) return project;

    const member = await this.projectMemberModel.findOne({ projectId, userId });
    if (!member) {
      throw new ForbiddenException('Bạn không phải thành viên của dự án này');
    }
    return project;
  }

  async assertHasRole(projectId: string, userId: string, roles: ProjectRole[]) {
    const project = await this.projectModel.findById(projectId);
    if (!project) throw new NotFoundException('Không tìm thấy dự án');
    if (project.ownerId.toString() === userId) return project;

    const member = await this.projectMemberModel.findOne({ projectId, userId });
    if (!member || !roles.includes(member.role as ProjectRole)) {
      throw new ForbiddenException(
        roles.length === 1 && roles[0] === 'Admin'
          ? 'Chỉ Quản trị mới được thực hiện hành động này'
          : 'Bạn không đủ quyền thực hiện hành động này',
      );
    }
    return project;
  }

  async isMember(projectId: string, userId: string): Promise<boolean> {
    try {
      return (await this.getEffectiveRole(projectId, userId)) !== null;
    } catch {
      return false;
    }
  }
}
