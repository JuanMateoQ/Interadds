export function createExpirationDate(minutesFromNow: number): Date {
  return new Date(Date.now() + minutesFromNow * 60 * 1000);
}

export function isExpired(expirationDate: Date, referenceUtcNow: Date = new Date()): boolean {
  return referenceUtcNow.getTime() > new Date(expirationDate).getTime();
}