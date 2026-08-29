ALTER TABLE "Device"
ADD COLUMN "pushToken" TEXT,
ADD COLUMN "pushUpdatedAt" TIMESTAMP(3);

CREATE UNIQUE INDEX "Device_pushToken_key" ON "Device"("pushToken");
