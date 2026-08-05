import type { FastifyInstance } from 'fastify';
import { requireAuth } from '../auth.js';
import { db } from '../db.js';
import { redis } from '../redis.js';
import { envelopeSchema, receiptSchema } from '../schemas.js';

export async function messageRoutes(app: FastifyInstance): Promise<void> {
  app.post('/api/v1/messages', async (request, reply) => {
    const claims = await requireAuth(request);
    const input = envelopeSchema.parse(request.body);
    if (claims.deviceId !== input.senderDeviceId) {
      return reply.code(403).send({ error: 'Sender device mismatch' });
    }
    const result = await db.query<{ event_id: string }>(
      `WITH inserted AS (
         INSERT INTO messages (
           id, conversation_id, sender_user_id, sender_device_id, recipient_user_id,
           ciphertext, nonce, client_created_at
         ) VALUES ($1,$2,$3,$4,$5,$6,$7,to_timestamp($8 / 1000.0))
         ON CONFLICT (id) DO NOTHING
         RETURNING id
       ), event AS (
         INSERT INTO sync_events (user_id, event_type, payload)
         SELECT $5, 'envelope', jsonb_build_object(
           'messageId',$1,'conversationId',$2,'senderId',$3,
           'ciphertext',$6,'nonce',$7,'createdAtEpochMs',$8
         ) WHERE EXISTS (SELECT 1 FROM inserted)
         RETURNING id
       ) SELECT id::text AS event_id FROM event`,
      [
        input.messageId,
        input.conversationId,
        claims.sub,
        input.senderDeviceId,
        input.recipientUserId,
        input.ciphertext,
        input.nonce,
        input.createdAtEpochMs,
      ],
    );
    const event = {
      type: 'envelope',
      conversationId: input.conversationId,
      messageId: input.messageId,
      senderId: claims.sub,
      payload: JSON.stringify({ ciphertext: input.ciphertext, nonce: input.nonce }),
    };
    await redis.publish(`user:${input.recipientUserId}`, JSON.stringify(event));
    return reply.code(202).send({ accepted: true, cursor: result.rows[0]?.event_id ?? null });
  });

  app.get('/api/v1/sync', async (request) => {
    const claims = await requireAuth(request);
    const cursor = Number((request.query as { cursor?: string }).cursor ?? 0);
    const result = await db.query(
      `SELECT id::text AS cursor, event_type AS type, payload, created_at
       FROM sync_events WHERE user_id = $1 AND id > $2
       ORDER BY id ASC LIMIT 500`,
      [claims.sub, Number.isFinite(cursor) ? cursor : 0],
    );
    const nextCursor = result.rows.at(-1)?.cursor ?? String(cursor);
    return { nextCursor, events: result.rows };
  });

  app.post('/api/v1/messages/receipt', async (request, reply) => {
    const claims = await requireAuth(request);
    const input = receiptSchema.parse(request.body);
    const message = await db.query<{ sender_user_id: string; conversation_id: string }>(
      `UPDATE messages SET receipt_state = $1, receipt_updated_at = NOW()
       WHERE id = $2 AND recipient_user_id = $3
       RETURNING sender_user_id, conversation_id`,
      [input.state, input.messageId, claims.sub],
    );
    const row = message.rows[0];
    if (!row) return reply.code(404).send({ error: 'Message not found' });
    await redis.publish(`user:${row.sender_user_id}`, JSON.stringify({
      type: 'receipt',
      conversationId: row.conversation_id,
      messageId: input.messageId,
      state: input.state,
    }));
    return reply.code(202).send({ accepted: true });
  });
}
