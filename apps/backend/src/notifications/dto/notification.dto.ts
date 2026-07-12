import { IsEmail, IsNotEmpty, IsString } from 'class-validator';

export class TestEmailDto {
  @IsEmail()
  to!: string;

  @IsString()
  @IsNotEmpty()
  subject!: string;

  @IsString()
  @IsNotEmpty()
  body!: string;
}

export class TestSmsDto {
  @IsString()
  @IsNotEmpty()
  to!: string;

  @IsString()
  @IsNotEmpty()
  message!: string;
}

export class RegisterDeviceTokenDto {
  @IsString()
  @IsNotEmpty()
  token!: string;
}
