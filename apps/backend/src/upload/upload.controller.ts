import {
  Controller, Post, UseInterceptors, UploadedFile, UploadedFiles,
  BadRequestException, UseGuards, Get, Param, Res,
} from '@nestjs/common';
import { FileInterceptor, FilesInterceptor } from '@nestjs/platform-express';
import { extname, join } from 'path';
import * as crypto from 'crypto';
import * as fs from 'fs';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiConsumes } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '@trimly/types';
import type { Response } from 'express';

const UPLOADS_DIR = join(process.cwd(), 'uploads');
const ALLOWED_MIME = ['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'video/mp4', 'video/quicktime'];
const MAX_SIZE = 50 * 1024 * 1024;

function ensureDir(dir: string) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

@ApiTags('Uploads')
@Controller('upload')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SALON_OWNER)
@ApiBearerAuth()
export class UploadController {
  @Post()
  @ApiOperation({ summary: 'Upload a single file (image or video)' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(
    FileInterceptor('file', { limits: { fileSize: MAX_SIZE } }),
  )
  async uploadFile(@UploadedFile() file: any) {
    try {
      if (!file) throw new BadRequestException('No file provided');
      if (!ALLOWED_MIME.includes(file.mimetype)) {
        throw new BadRequestException('Only images (JPEG, PNG, WebP, GIF) and videos (MP4, MOV) are allowed');
      }
      const filename = `${crypto.randomUUID()}${extname(file.originalname)}`;
      const dir = join(UPLOADS_DIR, 'temp');
      ensureDir(dir);
      fs.writeFileSync(join(dir, filename), file.buffer);
      return {
        success: true,
        data: { url: `/uploads/${filename}`, filename, mimetype: file.mimetype, size: file.size },
      };
    } catch (e) {
      console.error("UPLOAD ERROR", e);
      throw e;
    }
  }

  @Post('bulk')
  @ApiOperation({ summary: 'Upload multiple files (max 10)' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(
    FilesInterceptor('files', 10, { limits: { fileSize: MAX_SIZE } }),
  )
  async uploadFiles(@UploadedFiles() files: any[]) {
    if (!files || files.length === 0) throw new BadRequestException('No files provided');
    const results = [];
    for (const file of files) {
      if (!ALLOWED_MIME.includes(file.mimetype)) continue;
      const filename = `${crypto.randomUUID()}${extname(file.originalname)}`;
      const dir = join(UPLOADS_DIR, 'temp');
      ensureDir(dir);
      fs.writeFileSync(join(dir, filename), file.buffer);
      results.push({ url: `/uploads/${filename}`, filename, mimetype: file.mimetype, size: file.size });
    }
    return { success: true, data: results };
  }

  @Get(':filename')
  async serveFile(@Param('filename') filename: string, @Res() res: Response) {
    const filePath = join(UPLOADS_DIR, 'temp', filename);
    if (!fs.existsSync(filePath)) {
      throw new BadRequestException('File not found');
    }
    return res.sendFile(filePath);
  }
}
