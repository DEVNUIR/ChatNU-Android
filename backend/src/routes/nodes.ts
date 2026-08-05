import type { FastifyInstance } from 'fastify';
import { db } from '../db.js';

export async function nodeRoutes(app: FastifyInstance): Promise<void> {
  app.get('/api/v1/nodes', async () => {
    const result = await db.query(
      `SELECT id, name, base_url AS host, websocket_url, region, trusted, active
       FROM relay_nodes WHERE active = TRUE ORDER BY trusted DESC, name ASC`,
    );
    return { nodes: result.rows };
  });
}
