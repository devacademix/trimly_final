/*
  Warnings:

  - A unique constraint covering the columns `[tenantId,name]` on the table `service_categories` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateEnum
CREATE TYPE "BusinessCategory" AS ENUM ('SALON', 'SPA', 'NAIL_STUDIO', 'BARBER', 'MAKEUP_STUDIO');

-- CreateEnum
CREATE TYPE "DocumentType" AS ENUM ('PAN', 'AADHAAR', 'GST', 'CANCELED_CHEQUE', 'PASSBOOK', 'SELFIE');

-- CreateEnum
CREATE TYPE "KycStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- CreateEnum
CREATE TYPE "OnboardingStep" AS ENUM ('WELCOME', 'MOBILE_VERIFICATION', 'BASIC_INFO', 'LOCATION', 'DETAILS', 'TIMING', 'PHOTOS', 'SERVICES', 'STAFF', 'BANK', 'KYC', 'SUBSCRIPTION', 'TOUR', 'COMPLETED');

-- AlterTable
ALTER TABLE "tenants" ADD COLUMN     "area" TEXT,
ADD COLUMN     "businessCategory" "BusinessCategory",
ADD COLUMN     "businessRegNumber" TEXT,
ADD COLUMN     "country" TEXT NOT NULL DEFAULT 'IN',
ADD COLUMN     "fullAddress" TEXT,
ADD COLUMN     "kycApprovedAt" TIMESTAMP(3),
ADD COLUMN     "kycRejectedAt" TIMESTAMP(3),
ADD COLUMN     "kycRemarks" TEXT,
ADD COLUMN     "kycStatus" "KycStatus" NOT NULL DEFAULT 'PENDING',
ADD COLUMN     "kycSubmittedAt" TIMESTAMP(3),
ADD COLUMN     "latitude" DOUBLE PRECISION,
ADD COLUMN     "longitude" DOUBLE PRECISION,
ADD COLUMN     "onboardingStep" "OnboardingStep" NOT NULL DEFAULT 'WELCOME',
ADD COLUMN     "state" TEXT;

-- CreateTable
CREATE TABLE "bank_details" (
    "id" UUID NOT NULL,
    "tenantId" UUID NOT NULL,
    "accountHolder" TEXT NOT NULL,
    "bankName" TEXT NOT NULL,
    "accountNumber" TEXT NOT NULL,
    "ifsc" TEXT NOT NULL,
    "upiId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "bank_details_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "kyc_documents" (
    "id" UUID NOT NULL,
    "tenantId" UUID NOT NULL,
    "documentType" "DocumentType" NOT NULL,
    "fileUrl" TEXT NOT NULL,
    "status" "KycStatus" NOT NULL DEFAULT 'PENDING',
    "remarks" TEXT,
    "verifiedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "kyc_documents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tenant_gallery" (
    "id" UUID NOT NULL,
    "tenantId" UUID NOT NULL,
    "url" TEXT NOT NULL,
    "mediaType" TEXT NOT NULL DEFAULT 'IMAGE',
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tenant_gallery_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "bank_details_tenantId_key" ON "bank_details"("tenantId");

-- CreateIndex
CREATE INDEX "kyc_documents_tenantId_idx" ON "kyc_documents"("tenantId");

-- CreateIndex
CREATE INDEX "tenant_gallery_tenantId_idx" ON "tenant_gallery"("tenantId");

-- CreateIndex
CREATE UNIQUE INDEX "service_categories_tenantId_name_key" ON "service_categories"("tenantId", "name");

-- AddForeignKey
ALTER TABLE "bank_details" ADD CONSTRAINT "bank_details_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kyc_documents" ADD CONSTRAINT "kyc_documents_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tenant_gallery" ADD CONSTRAINT "tenant_gallery_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;
