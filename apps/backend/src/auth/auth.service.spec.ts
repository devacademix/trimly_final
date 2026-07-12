import { BadRequestException, ConflictException, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { AuthService } from './auth.service';
import { UserRole, UserStatus, AuthProvider } from '@trimly/types';

describe('AuthService', () => {
  let service: AuthService;
  let prisma: any;
  let jwtService: any;

  beforeEach(() => {
    process.env.JWT_ACCESS_SECRET = 'test-secret-at-least-32-characters-long';

    prisma = {
      user: {
        findUnique: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      otpSecret: {
        upsert: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
      },
      userSession: {
        create: jest.fn(),
        findFirst: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
      },
    };

    jwtService = {
      sign: jest.fn().mockReturnValue('signed.jwt.token'),
    };

    service = new AuthService(prisma, jwtService);
  });

  describe('register', () => {
    it('rejects a duplicate email', async () => {
      prisma.user.findUnique.mockResolvedValue({ id: 'existing-user' });

      await expect(
        service.register({ email: 'a@b.com', fullName: 'A B', role: UserRole.CUSTOMER }),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('hashes the password before persisting', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      prisma.user.create.mockImplementation(({ data }: any) => ({ id: 'new-user', ...data }));

      await service.register({
        email: 'a@b.com',
        password: 'Sup3rSecret!',
        fullName: 'A B',
        role: UserRole.CUSTOMER,
      });

      const createArgs = prisma.user.create.mock.calls[0][0];
      expect(createArgs.data.passwordHash).toBeDefined();
      expect(createArgs.data.passwordHash).not.toBe('Sup3rSecret!');
    });
  });

  describe('login', () => {
    it('rejects an unknown email', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      await expect(service.login({ email: 'nobody@x.com', password: 'x' })).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });

    it('rejects a wrong password', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'u1',
        status: UserStatus.ACTIVE,
        passwordHash: await bcrypt.hash('correct-password', 10),
      });

      await expect(service.login({ email: 'a@b.com', password: 'wrong-password' })).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });

    it('issues a session for correct credentials', async () => {
      const passwordHash = await bcrypt.hash('correct-password', 10);
      prisma.user.findUnique.mockResolvedValue({
        id: 'u1',
        role: UserRole.CUSTOMER,
        status: UserStatus.ACTIVE,
        email: 'a@b.com',
        passwordHash,
      });
      prisma.user.update.mockResolvedValue({});
      prisma.userSession.create.mockResolvedValue({});

      const session = await service.login({ email: 'a@b.com', password: 'correct-password' });

      expect(session.accessToken).toBe('signed.jwt.token');
      expect(session.user.id).toBe('u1');
    });
  });

  describe('verifyOtp', () => {
    it('rejects an expired/missing OTP record', async () => {
      prisma.otpSecret.findUnique.mockResolvedValue(null);
      await expect(service.verifyOtp('+911234567890', '123456')).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects after too many invalid attempts', async () => {
      prisma.otpSecret.findUnique.mockResolvedValue({
        phoneNormalized: '+911234567890',
        otpHash: 'irrelevant',
        expiresAt: new Date(Date.now() + 60_000),
        attempts: 5,
      });

      await expect(service.verifyOtp('+911234567890', '123456')).rejects.toBeInstanceOf(BadRequestException);
    });

    it('creates a new customer user on first successful OTP verification', async () => {
      const otpHash = await bcrypt.hash('123456', 10);
      prisma.otpSecret.findUnique.mockResolvedValue({
        phoneNormalized: '+911234567890',
        otpHash,
        expiresAt: new Date(Date.now() + 60_000),
        attempts: 0,
      });
      prisma.otpSecret.delete.mockResolvedValue({});
      prisma.user.findUnique.mockResolvedValue(null);
      prisma.user.create.mockResolvedValue({
        id: 'new-customer',
        role: UserRole.CUSTOMER,
        status: UserStatus.ACTIVE,
        phone: '+911234567890',
        authProvider: AuthProvider.OTP,
      });
      prisma.userSession.create.mockResolvedValue({});

      const session = await service.verifyOtp('+911234567890', '123456');

      expect(prisma.user.create).toHaveBeenCalled();
      expect(session.user.role).toBe(UserRole.CUSTOMER);
    });
  });
});
