import { buildApiServer, buildRealtimeServer } from './app.js';
import { config } from './config.js';
import { closeDatabase } from './db.js';
import { migrate } from './migrate.js';
import { ensureRedis, redis } from './redis.js';

async function main(): Promise<void> {
  if (config.RUN_MIGRATIONS) await migrate();
  await ensureRedis();
  const api = await buildApiServer();
  const realtime = await buildRealtimeServer();
  await Promise.all([
    api.listen({ host: '0.0.0.0', port: config.API_PORT }),
    realtime.listen({ host: '0.0.0.0', port: config.WS_PORT }),
  ]);

  const shutdown = async () => {
    await Promise.allSettled([api.close(), realtime.close(), closeDatabase()]);
    redis.disconnect();
  };
  process.once('SIGTERM', shutdown);
  process.once('SIGINT', shutdown);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
