import { IsIn } from 'class-validator';

export const PROJECT_ROLES = ['Admin', 'Manager', 'Member'] as const;
export type ProjectRole = (typeof PROJECT_ROLES)[number];

export class UpdateMemberRoleDto {
  @IsIn(PROJECT_ROLES, { message: 'Vai trò không hợp lệ' })
  role: ProjectRole;
}
