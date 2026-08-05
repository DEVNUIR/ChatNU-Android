import { createHash, randomBytes } from 'node:crypto';
import type { FastifyInstance, FastifyRequest } from 'fastify';
import { db } from './db.js';

export type JwtClaims = { sub: string; deviceId: string; username: string };

export async function requireAuth(request: FastifyRequest): Promise<JwtClaims> {
  await request.jwtVerify();
  return request.user as JwtClaims;
}

export async function issueTokens(
  app: FastifyInstance,
  user: { id: string; username: string },
  deviceId: string,
): Promise<{ accessToken: string; refreshToken: string }> {
  const accessToken = app.jwt.sign(
    { sub: user.id, username: user.username, deviceId },
    { expiresIn: '15m' },
  );
  const refreshToken = randomBytes(48).toString('base64url');
  const hash = createHash('sha256').update(refreshToken).digest('hex');
  await db.query(
    `INSERT INTO refresh_tokens (user_id, device_id, token_hash, expires_at)
     VALUES ($1, $2, $3, NOW() + INTERVAL '30 days')`,
    [user.id, deviceId, hash],
  );
  return { accessToken, refreshToken };
}
