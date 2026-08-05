import { z } from 'zod';

export const registerSchema = z.object({
  username: z.string().trim().min(3).max(32).regex(/^[a-zA-Z0-9_.-]+$/),
  displayName: z.string().trim().min(2).max(80),
  deviceId: z.string().uuid(),
  publicIdentityKey: z.string().min(40).max(4096),
});

export const challengeSchema = z.object({
  username: z.string().trim().min(3).max(32),
  deviceId: z.string().uuid(),
});

export const verifyChallengeSchema = challengeSchema.extend({
  challengeId: z.string().uuid(),
  signature: z.string().min(32).max(4096),
});

export const envelopeSchema = z.object({
  messageId: z.string().uuid(),
  conversationId: z.string().min(1).max(128),
  senderDeviceId: z.string().min(1).max(128),
  recipientUserId: z.string().uuid(),
  ciphertext: z.string().min(1).max(2_000_000),
  nonce: z.string().min(8).max(256),
  createdAtEpochMs: z.number().int().positive(),
});

export const receiptSchema = z.object({
  messageId: z.string().uuid(),
  state: z.enum(['delivered', 'read']),
});

export type EnvelopeInput = z.infer<typeof envelopeSchema>;
