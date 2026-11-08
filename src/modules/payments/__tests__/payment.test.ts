import { describe, it, expect } from 'vitest';
import { hashPassword, verifyPassword } from '@/lib/crypto/password';
import { generateSecureRandomHex, buildIdempotencyKey } from '@/lib/crypto/random';
import { createExpirationDate, isExpired } from '@/lib/crypto/expiration';

describe('Mateo Quisilema - Criptografía y Base de Pagos (RS-12, RS-15, RS-42, RNF-22)', () => {
  it('RS-12 y RNF-03: deriva contraseñas con sal única y verifica correctamente', async () => {
    const plain = 'ClaveSeguraInteradds2026!';
    const hash1 = await hashPassword(plain);
    const hash2 = await hashPassword(plain);

    expect(hash1).not.toBe(plain);
    expect(hash1).not.toBe(hash2); // Sal diferente en cada ejecución
    expect(await verifyPassword(plain, hash1)).toBe(true);
    expect(await verifyPassword('ClaveIncorrecta', hash1)).toBe(false);
  });

  it('RS-15: genera tokens aleatorios criptográficamente seguros sin colisiones', () => {
    const token1 = generateSecureRandomHex(32);
    const token2 = generateSecureRandomHex(32);

    expect(token1).toHaveLength(64);
    expect(token1).not.toBe(token2);
  });

  it('RS-42: detecta correctamente credenciales temporales caducadas vs vigentes', () => {
    const futureDate = createExpirationDate(15);
    const pastDate = new Date(Date.now() - 60_000);

    expect(isExpired(futureDate)).toBe(false);
    expect(isExpired(pastDate)).toBe(true);
  });

  it('RNF-22: genera claves de idempotencia deterministas por contrato y tramo (50/50)', () => {
    const keyAnticipo = buildIdempotencyKey('ctr-001', 'ANTICIPO');
    const keySaldo = buildIdempotencyKey('ctr-001', 'SALDO');

    expect(keyAnticipo).toBe('INTERADDS-ctr-001-ANTICIPO');
    expect(keySaldo).toBe('INTERADDS-ctr-001-SALDO');
    expect(keyAnticipo).not.toBe(keySaldo);
  });
});