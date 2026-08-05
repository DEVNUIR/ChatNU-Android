import 'dotenv/config';
import { z } from 'zod';

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  API_PORT: z.coerce.number().int().positive().default(8080),
  WS_PORT: z.coerce.number().int().positive().default(8081),
  DATABASE_URL: z.string().min(1).default('postgres://chatnu:chatnu@localhost:5432/chatnu'),
  REDIS_URL: z.string().min(1).default('redis://localhost:6379'),
  JWT_SECRET: z.string().min(32).default('development-only-change-this-secret-now'),
  ATTACHMENT_DIR: z.string().default('/data/attachments'),
  MAX_ATTACHMENT_BYTES: z.coerce.number().int().positive().default(25 * 1024 * 1024),
  RUN_MIGRATIONS: z.coerce.boolean().default(true),
});

export const config = schema.parse(process.env);
