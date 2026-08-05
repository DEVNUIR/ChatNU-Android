import { describe, expect, it } from 'vitest';
import { envelopeSchema, registerSchema } from '../src/schemas.js';

describe('public API schemas', () => {
  it('accepts a valid device registration', () => {
    const result = registerSchema.parse({
      username: 'amir.devnu',
      displayName: 'Amir',
      deviceId: '7d77eeaa-a591-49e2-bfc6-77d78701bd99',
      publicIdentityKey: 'A'.repeat(80),
    });
    expect(result.username).toBe('amir.devnu');
  });

  it('rejects plaintext-shaped empty envelopes', () => {
    expect(() => envelopeSchema.parse({})).toThrow();
  });
});
