import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import multipart from '@fastify/multipart';
import rateLimit from '@fastify/rate-limit';
import Fastify, { type FastifyInstance } from 'fastify';
import { config } from './config.js';
import { attachmentRoutes } from './routes/attachments.js';
import { authRoutes } from './routes/auth.js';
import { healthRoutes } from './routes/health.js';
import { messageRoutes } from './routes/messages.js';
import { nodeRoutes } from './routes/nodes.js';
import { registerRealtime } from './realtime.js';

async function common(app: FastifyInstance): Promise<void> {
  await app.register(cors, { origin: false });
  await app.register(jwt, { secret: config.JWT_SECRET });
  await app.register(rateLimit, { max: 120, timeWindow: '1 minute' });
}

export async function buildApiServer(): Promise<FastifyInstance> {
  const app = Fastify({ logger: true, trustProxy: true, bodyLimit: 2_500_000 });
  await common(app);
  await app.register(multipart);
  await healthRoutes(app);
  await authRoutes(app);
  await messageRoutes(app);
  await nodeRoutes(app);
  await attachmentRoutes(app);
  return app;
}

export async function buildRealtimeServer(): Promise<FastifyInstance> {
  const app = Fastify({ logger: true, trustProxy: true });
  await common(app);
  await registerRealtime(app);
  return app;
}
