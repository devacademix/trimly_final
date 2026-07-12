import { IsUUID } from 'class-validator';

export class StartRoomDto {
  @IsUUID()
  recipientId!: string;
}
