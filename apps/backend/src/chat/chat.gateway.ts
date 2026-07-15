import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { SkipThrottle } from '@nestjs/throttler';
import { ChatService } from './chat.service';
import { PrismaService } from '../prisma/prisma.service';
import { UserStatus } from '@trimly/types';

// The global ThrottlerGuard is HTTP-request/response shaped and doesn't apply
// cleanly to Socket.IO's message events; skip it here rather than risk it
// breaking realtime chat.
@SkipThrottle()
@WebSocketGateway({
  cors: {
    // Evaluated per-connection (not at class-decoration time), so this always
    // sees CORS_ORIGINS after ConfigModule has loaded the .env file.
    origin: (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
      const allowed = (process.env.CORS_ORIGINS || 'http://localhost:3000')
        .split(',')
        .map((o) => o.trim());
      if (!origin || origin === 'null' || origin === 'file://' || allowed.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error(`Not allowed by CORS: ${origin}`));
      }
    },
    credentials: true,
  },
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  constructor(
    private chatService: ChatService,
    private jwtService: JwtService,
    private prisma: PrismaService,
  ) {}

  // Authenticate the socket using the same access token used for REST calls.
  // Client is expected to connect with `io(url, { auth: { token } })`.
  async handleConnection(client: Socket) {
    try {
      console.info(`[CHAT GATEWAY] Client connecting: ${client.id}`);
      const authToken = client.handshake.auth?.token as string | undefined;
      const headerToken = client.handshake.headers.authorization?.toString().replace(/^Bearer\s+/i, '');
      const token = authToken || headerToken;

      if (!token) {
        throw new Error('Missing auth token');
      }

      const payload = await this.jwtService.verifyAsync(token, {
        secret: process.env.JWT_ACCESS_SECRET,
      });

      const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
      if (!user || user.status !== UserStatus.ACTIVE) {
        throw new Error('User not found or inactive');
      }

      client.data.userId = user.id;
      console.info(`[CHAT GATEWAY] Authenticated client: ${client.id} for user ${user.id}`);
    } catch (err) {
      console.warn(`[CHAT GATEWAY] Rejected unauthenticated connection: ${client.id} | Error: ${(err as Error).message}`);
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket) {
    console.info(`[CHAT GATEWAY] Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('join_room')
  async handleJoinRoom(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { roomId: string },
  ) {
    const userId = client.data.userId as string | undefined;
    if (!userId) return;

    const isParticipant = await this.chatService.isRoomParticipant(payload.roomId, userId);
    if (!isParticipant) {
      console.warn(`[CHAT GATEWAY] User ${userId} denied join to room ${payload.roomId}`);
      return;
    }

    client.join(payload.roomId);
  }

  @SubscribeMessage('send_message')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { roomId: string; text: string },
  ) {
    const userId = client.data.userId as string | undefined;
    if (!userId) return;

    const isParticipant = await this.chatService.isRoomParticipant(payload.roomId, userId);
    if (!isParticipant) {
      return;
    }

    // senderId always comes from the authenticated socket, never the client payload.
    const msg = await this.chatService.saveMessage(payload.roomId, userId, payload.text);
    this.server.to(payload.roomId).emit('message_received', msg);
  }
}
