import { Controller, Get, Post, Body, Param, ParseUUIDPipe, UseGuards } from '@nestjs/common';
import { ChatService } from './chat.service';
import { ApiResponse } from '@trimly/types';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { StartRoomDto } from './dto/chat.dto';

@ApiTags('Real-time Support Chat')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('chat')
export class ChatController {
  constructor(private chatService: ChatService) {}

  @Get('rooms')
  @ApiOperation({ summary: 'List all active chat rooms for current user' })
  async getRooms(@CurrentUser() user: any): Promise<ApiResponse<any>> {
    const rooms = await this.chatService.getRooms(user.id);
    return {
      success: true,
      data: rooms,
    };
  }

  @Post('rooms')
  @ApiOperation({ summary: 'Initiate or retrieve active chat room with another user' })
  async startRoom(
    @CurrentUser() user: any,
    @Body() dto: StartRoomDto,
  ): Promise<ApiResponse<any>> {
    const room = await this.chatService.createOrGetRoom(user.id, dto.recipientId);
    return {
      success: true,
      data: room,
    };
  }

  @Get('rooms/:id/messages')
  @ApiOperation({ summary: 'Retrieve chat message history for room' })
  async getMessages(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: any): Promise<ApiResponse<any>> {
    const messages = await this.chatService.getMessages(id, user.id);
    return {
      success: true,
      data: messages,
    };
  }
}
