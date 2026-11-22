import { BadRequestException, CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from '../decorators/roles.decorator';
import { ProjectAccessService, ProjectRole } from '../project-access/project-access.service';

// Dùng cùng JwtAuthGuard; route phải có param `:id` hoặc `:projectId` là id dự án.
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly access: ProjectAccessService,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const roles = this.reflector.getAllAndOverride<ProjectRole[]>(ROLES_KEY, [
      ctx.getHandler(),
      ctx.getClass(),
    ]);
    if (!roles || roles.length === 0) return true;

    const req = ctx.switchToHttp().getRequest();
    const projectId: string | undefined = req.params?.projectId ?? req.params?.id;
    if (!projectId) throw new BadRequestException('Thiếu mã dự án');

    await this.access.assertHasRole(projectId, req.user.userId, roles);
    return true;
  }
}
