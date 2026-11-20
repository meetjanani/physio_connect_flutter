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
   amount) a Payment Link and a UPI QR, the same way GIFT City Carpool does
   (UPI link first, standard link if Razorpay refuses UPI links, e.g. in test
   mode). It saves their ids in the **Razorpay order's notes** (no database
   change) and returns `paymentLinkUrl` / `qrCodeUrl`. If neither can be made,
   it returns Razorpay's reason as `webPaymentError` and the website shows it.
2. The website shows a dialog: **Pay on this device** opens the link in a new
   tab; **Scan QR** shows the UPI QR (Razorpay's QR image, or a QR of the
   payment link if the QR could not be created).
3. The website polls `verify-razorpay-payment` with `checkStatusOnly: true`
   every 3 s. The function reads the ids from the order notes and checks, in
   order: the order's own payments, the link, the QR, and recent payments whose
   notes carry this order. On a captured payment for the right amount it marks
   the bookings paid with the same code the Android flow uses. It never records
   a failure.
4. `razorpay-webhook` confirms the bookings even if the patient closes the tab
   right after paying.

**Doctor payouts (Route):** link and QR payments can't carry the order's
transfer, so the doctor's held transfer (`on_hold`) is created right after
capture with the same split. `release-doctor-payment` works the same for all.

## Deploy (one time)

No database migration is needed.

```bash
# 1. Functions (the website keeps saying "not set up yet" until these are deployed)
supabase functions deploy create-razorpay-order
supabase functions deploy verify-razorpay-payment
supabase functions deploy razorpay-webhook --no-verify-jwt
supabase secrets set RAZORPAY_WEBHOOK_SECRET=<any long random string>
```

2. Razorpay Dashboard → Settings → Webhooks → Add:
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
