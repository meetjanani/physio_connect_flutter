# Website payments: Payment Link + UPI QR

Razorpay hasn't approved the website domain for embedded Checkout yet, so the
**website** pays through a Razorpay **Payment Link** (Razorpay-hosted payment
page: UPI apps, cards, wallets) and a **UPI QR code**. Neither needs the website
to be approved. The **Android app is unchanged** and keeps using the native
Razorpay SDK + signature verification.

The server code is in this repo (`supabase/functions/`). Until it is deployed,
the website shows *"Online payment on the website is not available yet. Please
complete this booking in the PhysioConnect Android app."* No broken checkout is
ever shown.

## How it works

1. The website calls `create-razorpay-order` with `"channel": "web"`. After the
   normal order, the function creates (or reuses, if still open and the same
   amount) a Payment Link and a UPI QR, saves their ids on the bookings
   (`webPaymentLinkId`, `webQrCodeId`) and returns `paymentLinkUrl` /
   `qrCodeUrl`.
2. The website shows a dialog: **Pay on this device** opens the link in a new
   tab; **Scan QR** shows the UPI QR (Razorpay's QR image, or a QR of the
   payment link if the QR could not be created).
3. The website polls `verify-razorpay-payment` with `checkStatusOnly: true`
   every 3 s. The function asks Razorpay whether the link / QR has a captured
   payment for the right amount and, if so, marks the bookings paid with the
   same code the Android flow uses. It never records a failure.
4. `razorpay-webhook` confirms the bookings even if the patient closes the tab
   right after paying.

**Doctor payouts (Route):** the Payment Link carries the same held transfer as
the Android order (`options.order.transfers`, `on_hold`). QR payments can't
carry transfers, so the held transfer is created right after capture.
`release-doctor-payment` works the same for all three.

## Deploy (one time)

```bash
# 1. DB columns
supabase db push        # or run migrations/20261119150000_web_payment_link_qr.sql in the SQL editor

# 2. Functions
supabase functions deploy create-razorpay-order
supabase functions deploy verify-razorpay-payment
supabase functions deploy razorpay-webhook --no-verify-jwt
supabase secrets set RAZORPAY_WEBHOOK_SECRET=<any long random string>
```

3. Razorpay Dashboard → Settings → Webhooks → Add:
   URL `https://cjnxrkzrmeetzragwrlm.supabase.co/functions/v1/razorpay-webhook`,
   secret = the value above, events `payment_link.paid` and `qr_code.credited`.
   Do this in **test mode** and again in **live mode** (they are separate).

## Testing in Razorpay test mode

Use **test** keys (`rzp_test_…`) in the `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET`
function secrets.

- **Payment Link: works in test mode.** Open the link and pay with a test
  card or the test UPI id `success@razorpay`; the website confirms within a
  few seconds.
- **UPI QR: can't be paid in test mode.** A real UPI app can't pay a test QR.
  The QR Codes API also needs the QR / Smart Collect feature on the account;
  if it isn't enabled, `qrCodeUrl` is a QR of the payment link instead (scan
  it with a phone, it opens the same payment page), so this still works.
- Embedded Checkout (`checkout.js`) is not used on the website. It would work
  with test keys on any domain, but in live mode it needs the website approved.

## Going live

Live keys need the Razorpay account activated (KYC). Payment Links work on an
activated account without the website being approved. For the live UPI QR,
ask Razorpay support to enable QR Codes if `qrCodeUrl` comes back from the
QR-of-link fallback.
