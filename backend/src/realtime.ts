import type { FastifyInstance } from 'fastify';
import websocket from '@fastify/websocket';
import { redis } from './redis.js';

const WEBSOCKET_OPEN = 1;

export async function registerRealtime(app: FastifyInstance): Promise<void> {
  await app.register(websocket);

  app.get('/realtime', { websocket: true }, async (socket, request) => {
    try {
      const queryToken = (request.query as { token?: string }).token;
      const headerToken = request.headers.authorization?.replace(/^Bearer\s+/i, '');
      const token = queryToken ?? headerToken;
      if (!token) return socket.close(4401, 'Authentication required');

      const claims = app.jwt.verify<{ sub: string; deviceId: string }>(token);
      const subscriber = redis.duplicate();
      await subscriber.connect();
      const channel = `user:${claims.sub}`;
      await subscriber.subscribe(channel);

      subscriber.on('message', (_channel, payload) => {
        if (socket.readyState === WEBSOCKET_OPEN) socket.send(payload);
      });
      socket.send(JSON.stringify({ type: 'connected', payload: JSON.stringify({ deviceId: claims.deviceId }) }));

      socket.on('message', async (raw) => {
        try {
          const event = JSON.parse(raw.toString()) as {
            type?: string;
            recipientUserId?: string;
            conversationId?: string;
            typing?: boolean;
          };
          if (event.type === 'typing' && event.recipientUserId && event.conversationId) {
            await redis.publish(`user:${event.recipientUserId}`, JSON.stringify({
              type: 'typing',
              conversationId: event.conversationId,
              senderId: claims.sub,
              payload: JSON.stringify({ typing: Boolean(event.typing) }),
            }));
          }
        } catch {
          if (socket.readyState === WEBSOCKET_OPEN) {
            socket.send(JSON.stringify({ type: 'error', payload: 'Invalid realtime event' }));
          }
        }
      });

      socket.on('close', async () => {
        await subscriber.unsubscribe(channel).catch(() => undefined);
        subscriber.disconnect();
      });
    } catch {
      socket.close(4401, 'Invalid token');
    }
  });
}
