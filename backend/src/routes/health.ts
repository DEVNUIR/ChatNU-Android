import type { FastifyInstance } from 'fastify';
import { db } from '../db.js';
import { redis } from '../redis.js';

export async function healthRoutes(app: FastifyInstance): Promise<void> {
  app.get('/api/v1/health', async () => {
    const database = await db.query('SELECT 1 AS ok').then(() => 'up').catch(() => 'down');
    const cache = await redis.ping().then(() => 'up').catch(() => 'down');
    return {
      status: database === 'up' && cache === 'up' ? 'ok' : 'degraded',
      version: '0.1.0',
      nodeId: 'chatnu.devnu.ir',
      services: { database, cache },
    };
  });
}
