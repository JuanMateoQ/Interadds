-- CreateEnum
CREATE TYPE "Role" AS ENUM ('CLIENTE', 'PROVEEDOR', 'ADMIN_SISTEMA');

-- CreateEnum
CREATE TYPE "ServiceStatus" AS ENUM ('BORRADOR', 'PUBLICADO', 'PAUSADO');

-- CreateEnum
CREATE TYPE "ContractStatus" AS ENUM ('GENERADO', 'FIRMADO_POR_UNA_PARTE', 'VIGENTE', 'ANTICIPO_PAGADO', 'CONTENIDO_ENTREGADO', 'CONTENIDO_APROBADO', 'COMPLETADO');

-- CreateEnum
CREATE TYPE "CertificateStatus" AS ENUM ('ACTIVO', 'REVOCADO');

-- CreateEnum
CREATE TYPE "EvidenceType" AS ENUM ('ORIGEN', 'RECEPCION');

-- CreateEnum
CREATE TYPE "PaymentInstallment" AS ENUM ('ANTICIPO', 'SALDO');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('PENDIENTE', 'ORDEN_CREADA', 'CAPTURADO', 'FALLIDO');

-- CreateEnum
CREATE TYPE "DeliverableStatus" AS ENUM ('SUBIDO', 'APROBADO');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "role" "Role" NOT NULL DEFAULT 'CLIENTE',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "failedLoginAttempts" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProviderProfile" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "businessName" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "contactInfo" TEXT NOT NULL,

    CONSTRAINT "ProviderProfile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PasswordResetToken" (
    "id" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "used" BOOLEAN NOT NULL DEFAULT false,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PasswordResetToken_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Category" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "Category_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MarketingService" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "categoryId" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "price" DECIMAL(10,2) NOT NULL,
    "deliveryDays" INTEGER NOT NULL,
    "status" "ServiceStatus" NOT NULL DEFAULT 'PUBLICADO',
    "providerId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "MarketingService_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Contract" (
    "id" TEXT NOT NULL,
    "serviceId" TEXT NOT NULL,
    "clientId" TEXT NOT NULL,
    "providerId" TEXT NOT NULL,
    "templateVersion" TEXT NOT NULL DEFAULT 'v1.0',
    "contractText" TEXT NOT NULL,
    "totalPrice" DECIMAL(10,2) NOT NULL,
    "advanceAmount" DECIMAL(10,2) NOT NULL,
    "balanceAmount" DECIMAL(10,2) NOT NULL,
    "sha256Hash" TEXT NOT NULL,
    "status" "ContractStatus" NOT NULL DEFAULT 'GENERADO',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Contract_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Certificate" (
    "id" TEXT NOT NULL,
    "serialNumber" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "publicKeyPem" TEXT NOT NULL,
    "issuerName" TEXT NOT NULL DEFAULT 'Interadds Issuing CA',
    "issuedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "status" "CertificateStatus" NOT NULL DEFAULT 'ACTIVO',

    CONSTRAINT "Certificate_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SignatureEvidence" (
    "id" TEXT NOT NULL,
    "contractId" TEXT NOT NULL,
    "signerId" TEXT NOT NULL,
    "certificateId" TEXT,
    "eventStep" TEXT NOT NULL,
    "evidenceType" "EvidenceType" NOT NULL,
    "signedHash" TEXT NOT NULL,
    "signatureB64" TEXT NOT NULL,
    "nonce" TEXT NOT NULL,
    "timestampUtc" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SignatureEvidence_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Payment" (
    "id" TEXT NOT NULL,
    "contractId" TEXT NOT NULL,
    "installment" "PaymentInstallment" NOT NULL,
    "amount" DECIMAL(10,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "status" "PaymentStatus" NOT NULL DEFAULT 'PENDIENTE',
    "idempotencyKey" TEXT NOT NULL,
    "paypalOrderId" TEXT,
    "paypalCaptureId" TEXT,
    "paymentNonce" TEXT,
    "receiptJson" JSONB,
    "paidAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Payment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ChatRoom" (
    "id" TEXT NOT NULL,
    "contractId" TEXT,
    "isGeneral" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ChatRoom_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ChatMessage" (
    "id" TEXT NOT NULL,
    "roomId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "text" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ChatMessage_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Deliverable" (
    "id" TEXT NOT NULL,
    "contractId" TEXT NOT NULL,
    "filePath" TEXT NOT NULL,
    "mimeType" TEXT NOT NULL,
    "sizeBytes" INTEGER NOT NULL,
    "fileSha256" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "status" "DeliverableStatus" NOT NULL DEFAULT 'SUBIDO',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "approvedAt" TIMESTAMP(3),

    CONSTRAINT "Deliverable_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "ProviderProfile_userId_key" ON "ProviderProfile"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "PasswordResetToken_token_key" ON "PasswordResetToken"("token");

-- CreateIndex
CREATE UNIQUE INDEX "Category_name_key" ON "Category"("name");

-- CreateIndex
CREATE INDEX "MarketingService_title_idx" ON "MarketingService"("title");

-- CreateIndex
CREATE INDEX "MarketingService_categoryId_idx" ON "MarketingService"("categoryId");

-- CreateIndex
CREATE INDEX "MarketingService_price_idx" ON "MarketingService"("price");

-- CreateIndex
CREATE INDEX "Contract_clientId_idx" ON "Contract"("clientId");

-- CreateIndex
CREATE INDEX "Contract_providerId_idx" ON "Contract"("providerId");

-- CreateIndex
CREATE INDEX "Contract_status_idx" ON "Contract"("status");

-- CreateIndex
CREATE UNIQUE INDEX "Certificate_serialNumber_key" ON "Certificate"("serialNumber");

-- CreateIndex
CREATE UNIQUE INDEX "SignatureEvidence_nonce_key" ON "SignatureEvidence"("nonce");

-- CreateIndex
CREATE UNIQUE INDEX "Payment_idempotencyKey_key" ON "Payment"("idempotencyKey");

-- CreateIndex
CREATE UNIQUE INDEX "Payment_paypalOrderId_key" ON "Payment"("paypalOrderId");

-- CreateIndex
CREATE UNIQUE INDEX "Payment_paypalCaptureId_key" ON "Payment"("paypalCaptureId");

-- CreateIndex
CREATE UNIQUE INDEX "Payment_paymentNonce_key" ON "Payment"("paymentNonce");

-- CreateIndex
CREATE INDEX "Payment_contractId_idx" ON "Payment"("contractId");

-- CreateIndex
CREATE UNIQUE INDEX "Payment_contractId_installment_key" ON "Payment"("contractId", "installment");

-- CreateIndex
CREATE UNIQUE INDEX "ChatRoom_contractId_key" ON "ChatRoom"("contractId");

-- AddForeignKey
ALTER TABLE "ProviderProfile" ADD CONSTRAINT "ProviderProfile_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PasswordResetToken" ADD CONSTRAINT "PasswordResetToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MarketingService" ADD CONSTRAINT "MarketingService_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MarketingService" ADD CONSTRAINT "MarketingService_providerId_fkey" FOREIGN KEY ("providerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Contract" ADD CONSTRAINT "Contract_serviceId_fkey" FOREIGN KEY ("serviceId") REFERENCES "MarketingService"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Contract" ADD CONSTRAINT "Contract_clientId_fkey" FOREIGN KEY ("clientId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Contract" ADD CONSTRAINT "Contract_providerId_fkey" FOREIGN KEY ("providerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Certificate" ADD CONSTRAINT "Certificate_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SignatureEvidence" ADD CONSTRAINT "SignatureEvidence_contractId_fkey" FOREIGN KEY ("contractId") REFERENCES "Contract"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SignatureEvidence" ADD CONSTRAINT "SignatureEvidence_signerId_fkey" FOREIGN KEY ("signerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SignatureEvidence" ADD CONSTRAINT "SignatureEvidence_certificateId_fkey" FOREIGN KEY ("certificateId") REFERENCES "Certificate"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_contractId_fkey" FOREIGN KEY ("contractId") REFERENCES "Contract"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChatRoom" ADD CONSTRAINT "ChatRoom_contractId_fkey" FOREIGN KEY ("contractId") REFERENCES "Contract"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChatMessage" ADD CONSTRAINT "ChatMessage_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES "ChatRoom"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChatMessage" ADD CONSTRAINT "ChatMessage_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Deliverable" ADD CONSTRAINT "Deliverable_contractId_fkey" FOREIGN KEY ("contractId") REFERENCES "Contract"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
