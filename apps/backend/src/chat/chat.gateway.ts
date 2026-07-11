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
import { ChatService } from './chat.service';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  constructor(private chatService: ChatService) {}

  handleConnection(client: Socket) {
    const userId = client.handshake.query.userId as string;
    console.info(`[CHAT GATEWAY] Client connected: ${client.id} | User: ${userId}`);
  }

  handleDisconnect(client: Socket) {
    console.info(`[CHAT GATEWAY] Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('join_room')
  handleJoinRoom(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { roomId: string },
  ) {
    client.join(payload.roomId);
    console.info(`[CHAT GATEWAY] Client ${client.id} joined room ${payload.roomId}`);
  }

  @SubscribeMessage('send_message')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { roomId: string; senderId: string; text: string },
  ) {
    // Save to Database
    const msg = await this.chatService.saveMessage(payload.roomId, payload.senderId, payload.text);

    // Broadcast to room
    this.server.to(payload.roomId).emit('message_received', msg);
  }
}
