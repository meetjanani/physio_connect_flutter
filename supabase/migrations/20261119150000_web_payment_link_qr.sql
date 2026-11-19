-- Website payments (Razorpay Payment Link + UPI QR) while the website domain
-- is not yet approved for embedded Razorpay Checkout.
-- create-razorpay-order saves the ids; verify-razorpay-payment (checkStatusOnly)
-- and razorpay-webhook use them to confirm the payment server-side.

ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS "webPaymentLinkId" text;

ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS "webQrCodeId" text;

COMMENT ON COLUMN public.bookings."webPaymentLinkId" IS
  'Razorpay Payment Link id (plink_...) created for a website checkout.';
COMMENT ON COLUMN public.bookings."webQrCodeId" IS
  'Razorpay UPI QR code id (qr_...) created for a website checkout.';
