import { createPublicKey, randomBytes, randomUUID, verify } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { db } from '../db.js';
import { issueTokens } from '../auth.js';
import { redis } from '../redis.js';
import { challengeSchema, registerSchema, verifyChallengeSchema } from '../schemas.js';

export async function authRoutes(app: FastifyInstance): Promise<void> {
  app.post('/api/v1/auth/register', async (request, reply) => {
    const input = registerSchema.parse(request.body);
    const client = await db.connect();
    try {
      await client.query('BEGIN');
      const userResult = await client.query<{ id: string; username: string }>(
        `INSERT INTO users (username, display_name)
         VALUES ($1, $2)
         ON CONFLICT (username) DO UPDATE SET display_name = EXCLUDED.display_name
         RETURNING id, username`,
        [input.username.toLowerCase(), input.displayName],
      );
      const user = userResult.rows[0];
      if (!user) throw new Error('Unable to create user');
      await client.query(
        `INSERT INTO devices (id, user_id, public_identity_key, last_seen_at)
         VALUES ($1, $2, $3, NOW())
         ON CONFLICT (id) DO UPDATE SET public_identity_key = EXCLUDED.public_identity_key, last_seen_at = NOW()`,
        [input.deviceId, user.id, input.publicIdentityKey],
      );
      await client.query('COMMIT');
      const tokens = await issueTokens(app, user, input.deviceId);
      return reply.code(201).send({ userId: user.id, ...tokens });
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  });

  app.post('/api/v1/auth/challenge', async (request) => {
    const input = challengeSchema.parse(request.body);
    const challengeId = randomUUID();
    const nonce = randomBytes(48).toString('base64url');
    await redis.set(
      `auth:challenge:${challengeId}`,
      JSON.stringify({ ...input, nonce }),
      'EX',
      300,
    );
    return { challengeId, nonce, expiresInSeconds: 300 };
  });

  app.post('/api/v1/auth/verify', async (request, reply) => {
    const input = verifyChallengeSchema.parse(request.body);
    const key = `auth:challenge:${input.challengeId}`;
    const raw = await redis.get(key);
    if (!raw) return reply.code(401).send({ error: 'Challenge expired' });
    const challenge = JSON.parse(raw) as { username: string; deviceId: string; nonce: string };
    if (challenge.username !== input.username || challenge.deviceId !== input.deviceId) {
      return reply.code(401).send({ error: 'Challenge mismatch' });
    }
    const result = await db.query<{ id: string; username: string; public_identity_key: string }>(
      `SELECT u.id, u.username, d.public_identity_key
       FROM users u JOIN devices d ON d.user_id = u.id
       WHERE u.username = $1 AND d.id = $2 AND d.revoked_at IS NULL`,
      [input.username.toLowerCase(), input.deviceId],
    );
    const row = result.rows[0];
    if (!row) return reply.code(401).send({ error: 'Unknown device' });
    const publicKey = createPublicKey({
      key: Buffer.from(row.public_identity_key, 'base64'),
      format: 'der',
      type: 'spki',
    });
    const valid = verify(
      'sha256',
      Buffer.from(challenge.nonce),
      publicKey,
      Buffer.from(input.signature, 'base64'),
    );
    if (!valid) return reply.code(401).send({ error: 'Invalid signature' });
    await redis.del(key);
    return issueTokens(app, { id: row.id, username: row.username }, input.deviceId);
  });
}
