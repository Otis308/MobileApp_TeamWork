import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { ConfigService } from '@nestjs/config';
import { ProjectsService } from './projects.service';
import { Project } from './schemas/project.schema';
import { ProjectMember } from './schemas/project-member.schema';
import { User } from '../auth/schemas/user.schema';
import { Task } from '../tasks/schemas/task.schema';
import { Notification } from '../notifications/schemas/notification.schema';
import { AppGateway } from '../gateway/app.gateway';
import { ProjectAccessService } from '../common/project-access/project-access.service';

describe('ProjectsService', () => {
  let service: ProjectsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProjectsService,
        { provide: getModelToken(Project.name), useValue: {} },
        { provide: getModelToken(ProjectMember.name), useValue: {} },
        { provide: getModelToken(User.name), useValue: {} },
        { provide: getModelToken(Task.name), useValue: {} },
        { provide: getModelToken(Notification.name), useValue: {} },
        { provide: AppGateway, useValue: {} },
        { provide: ProjectAccessService, useValue: {} },
        { provide: ConfigService, useValue: { get: jest.fn() } },
      ],
    }).compile();

    service = module.get<ProjectsService>(ProjectsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
