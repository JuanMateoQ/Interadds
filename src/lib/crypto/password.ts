import bcrypt from 'bcryptjs';

const SALT_ROUNDS = 12;

export async function hashPassword(plainPassword: string): Promise<string> {
  if (!plainPassword || plainPassword.length < 1) {
    throw new Error('La contraseña no puede estar vacía');
  }
  return bcrypt.hash(plainPassword, SALT_ROUNDS);
}

export async function verifyPassword(plainPassword: string, storedHash: string): Promise<boolean> {
  if (!plainPassword || !storedHash) return false;
  return bcrypt.compare(plainPassword, storedHash);
}