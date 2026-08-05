import { createHash, randomUUID } from 'node:crypto';
import { createWriteStream } from 'node:fs';
import { mkdir, unlink } from 'node:fs/promises';
import path from 'node:path';
import { pipeline } from 'node:stream/promises';
import type { FastifyInstance } from 'fastify';
import { requireAuth } from '../auth.js';
import { config } from '../config.js';
import { db } from '../db.js';

export async function attachmentRoutes(app: FastifyInstance): Promise<void> {
  app.post('/api/v1/attachments', async (request, reply) => {
    const claims = await requireAuth(request);
    const part = await request.file({ limits: { fileSize: config.MAX_ATTACHMENT_BYTES, files: 1 } });
    if (!part) return reply.code(400).send({ error: 'Encrypted attachment required' });

    await mkdir(config.ATTACHMENT_DIR, { recursive: true });
    const id = randomUUID();
    const target = path.join(config.ATTACHMENT_DIR, `${id}.blob`);
    const hash = createHash('sha256');
    let byteSize = 0;

    part.file.on('data', (chunk: Buffer) => {
      hash.update(chunk);
      byteSize += chunk.length;
    });
    await pipeline(part.file, createWriteStream(target, { flags: 'wx', mode: 0o600 }));

    if (part.file.truncated) {
      await unlink(target).catch(() => undefined);
      return reply.code(413).send({ error: 'Encrypted attachment is too large' });
    }

    const digest = hash.digest('hex');
    await db.query(
      `INSERT INTO attachments (id, owner_user_id, storage_path, content_type, byte_size, sha256)
       VALUES ($1,$2,$3,$4,$5,$6)`,
      [id, claims.sub, target, part.mimetype, byteSize, digest],
    );
    return reply.code(201).send({ id, sha256: digest, byteSize });
  });
}
