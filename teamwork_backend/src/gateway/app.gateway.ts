import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Injectable, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ProjectAccessService } from '../common/project-access/project-access.service';

interface AuthenticatedSocket extends Socket {
  data: {
    userId?: string;
    projectIds?: Set<string>;
  };
}

@Injectable()
@WebSocketGateway({
  cors: {
    origin: '*',   // cho phép Flutter kết nối
  },
})
export class AppGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  private readonly logger = new Logger(AppGateway.name);

  @WebSocketServer()
  server: Server;

  constructor(
    private readonly jwtService: JwtService,
    private readonly access: ProjectAccessService,
  ) {}

  // User connect — verify the JWT sent in handshake.auth.token and
  // auto-join the personal room (never trust a self-asserted userId).
  async handleConnection(client: AuthenticatedSocket) {
    const token =
      (client.handshake.auth?.token as string | undefined) ??
      (client.handshake.headers?.authorization as string | undefined)
        ?.replace(/^Bearer\s+/i, '');

    if (!token) {
      this.logger.warn(`[WS] Missing token from ${client.id}, disconnecting`);
      client.disconnect(true);
      return;
    }

    try {
      const payload = await this.jwtService.verifyAsync(token);
      const userId = payload.sub?.toString();
      if (!userId) throw new Error('Missing sub claim');

      client.data.userId = userId;
      await client.join(`user_${userId}`);
      this.logger.log(`[WS] Client ${client.id} authenticated as ${userId}`);
    } catch {
      this.logger.warn(`[WS] Invalid token from ${client.id}, disconnecting`);
      client.disconnect(true);
    }
  }

  // User disconnect — announce offline presence for every project room
  // this socket had joined (best-effort presence).
  async handleDisconnect(client: AuthenticatedSocket) {
    this.logger.log(`[WS] Client disconnected: ${client.id}`);
    const userId = client.data.userId;
    if (!userId || !client.data.projectIds) return;
    for (const projectId of client.data.projectIds) {
      await this.announceOfflineIfGone(projectId, userId, client.id);
    }
  }

  // Client join vào room của project — chỉ cho phép thành viên/owner.
  // Flutter gọi: socket.emit('join_project', { projectId })
  @SubscribeMessage('join_project')
  async handleJoinProject(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { projectId: string },
  ) {
    const userId = client.data.userId;
    if (!userId || !data?.projectId) return;

    const allowed = await this.access.isMember(data.projectId, userId);
    if (!allowed) {
      this.logger.warn(`[WS] ${client.id} denied join to project_${data.projectId}`);
      return;
    }

    await client.join(`project_${data.projectId}`);
    (client.data.projectIds ??= new Set()).add(data.projectId);
    this.logger.log(`[WS] ${client.id} joined project_${data.projectId}`);

    // Presence: tell the room this user came online.
    this.server.to(`project_${data.projectId}`).emit('presence', {
      projectId: data.projectId,
      userId,
      online: true,
    });

    // Người mới vào cần biết ai đang online sẵn trong phòng.
    client.emit('presence_snapshot', {
      projectId: data.projectId,
      userIds: await this.onlineUserIds(data.projectId),
    });
  }

  // Client join room cá nhân — legacy path, kept for backward compatibility.
  // The room is already auto-joined on connect via the verified JWT, and
  // the client-supplied userId is only accepted if it matches that identity.
  @SubscribeMessage('join_user')
  async handleJoinUser(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { userId: string },
  ) {
    if (!data?.userId) return;
    if (client.data.userId && client.data.userId !== data.userId) {
      this.logger.warn(`[WS] ${client.id} tried to join another user's room`);
      return;
    }
    await client.join(`user_${data.userId}`);
    this.logger.log(`[WS] ${client.id} joined user_${data.userId}`);
  }

  // Client leave personal room — auto-joined rooms are cleaned up on disconnect.
  @SubscribeMessage('leave_user')
  async handleLeaveUser(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { userId: string },
  ) {
    if (!data?.userId) return;
    await client.leave(`user_${data.userId}`);
  }

  // Client rời project
  @SubscribeMessage('leave_project')
  async handleLeaveProject(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { projectId: string },
  ) {
    if (!data?.projectId) return;
    await client.leave(`project_${data.projectId}`);
    client.data.projectIds?.delete(data.projectId);

    if (client.data.userId) {
      await this.announceOfflineIfGone(data.projectId, client.data.userId, client.id);
    }
  }

  // ── Các method để Service gọi ──

  // Broadcast event đến tất cả người trong project
  emitToProject(projectId: string, event: string, data: any) {
    this.server.to(`project_${projectId}`).emit(event, data);
  }

  // Push event đến đúng 1 user
  emitToUser(userId: string, event: string, data: any) {
    this.server.to(`user_${userId}`).emit(event, data);
  }

  // ── Internal helpers ──

  // Các user đang có ít nhất một socket trong phòng dự án.
  private async onlineUserIds(
    projectId: string,
    excludeSocketId?: string,
  ): Promise<string[]> {
    const sockets = await this.server.in(`project_${projectId}`).fetchSockets();
    const ids = new Set<string>();
    for (const s of sockets) {
      if (s.id !== excludeSocketId && s.data?.userId) ids.add(s.data.userId);
    }
    return [...ids];
  }

  // Chỉ báo offline khi user không còn thiết bị nào khác trong phòng.
  private async announceOfflineIfGone(
    projectId: string,
    userId: string,
    excludeSocketId: string,
  ) {
    const stillOnline = await this.onlineUserIds(projectId, excludeSocketId);
    if (stillOnline.includes(userId)) return;
    this.server.to(`project_${projectId}`).emit('presence', {
      projectId,
      userId,
      online: false,
    });
  }
}
