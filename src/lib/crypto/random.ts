import { randomBytes } from 'crypto';

export function generateSecureRandomHex(byteLength: number = 32): string {
  return randomBytes(byteLength).toString('hex');
}

export function generateNonce(): string {
  return `${Date.now()}-${randomBytes(16).toString('hex')}`;
}

export function buildIdempotencyKey(contractId: string, installment: 'ANTICIPO' | 'SALDO'): string {
  return `INTERADDS-${contractId}-${installment}`;
}