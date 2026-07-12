import { Injectable, ForbiddenException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ChatService {
  constructor(private prisma: PrismaService) {}

  // Whether a user is a participant of a chat room
  async isRoomParticipant(roomId: string, userId: string): Promise<boolean> {
    const participant = await this.prisma.chatParticipant.findFirst({
      where: { roomId, userId },
    });
    return !!participant;
  }

  // List active rooms
  async getRooms(userId: string) {
    return this.prisma.chatRoom.findMany({
      where: {
        participants: {
          some: {
            userId,
          },
        },
      },
      include: {
        participants: {
          include: {
            user: { select: { id: true, fullName: true, profileImageUrl: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  // Create or fetch existing room between 2 participants
  async createOrGetRoom(p1: string, p2: string) {
    const existing = await this.prisma.chatRoom.findFirst({
      where: {
        AND: [
          { participants: { some: { userId: p1 } } },
          { participants: { some: { userId: p2 } } },
        ],
      },
    });

    if (existing) {
      return existing;
    }

    return this.prisma.chatRoom.create({
      data: {
        participants: {
          create: [
            { userId: p1 },
            { userId: p2 },
          ],
        },
      },
    });
  }

  // Save chat message
  async saveMessage(roomId: string, senderId: string, text: string) {
    const room = await this.prisma.chatRoom.findUnique({ where: { id: roomId } });
    if (!room) {
      throw new NotFoundException('Chat room not found');
    }

    return this.prisma.chatMessage.create({
      data: {
        roomId,
        senderId,
        text,
      },
    });
  }

  // Fetch paginated messages
  async getMessages(roomId: string, userId: string, limit = 50) {
    const isParticipant = await this.isRoomParticipant(roomId, userId);
    if (!isParticipant) {
      throw new ForbiddenException('You are not a participant of this chat room');
    }

    return this.prisma.chatMessage.findMany({
      where: { roomId },
      orderBy: { createdAt: 'asc' },
      take: limit,
    });
  }
}
