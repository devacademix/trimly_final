/**
 * @trimly/database — public entrypoint.
 *
 * Re-exports the generated Prisma client and the `PrismaClient` constructor so
 * the backend (and any workspace consumer) imports from a single place:
 *
 *   import { PrismaClient, UserRole } from '@trimly/database';
 */
export * from './generated/prisma/index.js';
export { PrismaClient } from './generated/prisma/index.js';
export type * from './generated/prisma/index.js';
