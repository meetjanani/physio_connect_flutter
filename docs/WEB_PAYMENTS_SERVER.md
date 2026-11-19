# Website payments: Payment Link + UPI QR (server changes)

Razorpay hasn't approved the website domain for embedded Checkout yet, so the
**website** pays through a Razorpay **Payment Link** and a **UPI QR code**
(the same approach as GIFTCity Carpool). The **Android app is unchanged** and
keeps using the native Razorpay SDK + signature verification.

The Flutter side is done. Until the two Supabase Edge Functions below are
updated, the website shows *"Online payment on the website is not available
yet. Please complete this booking in the PhysioConnect Android app."*. No
broken checkout is ever shown.

The function source isn't in this repo; it lives in the Supabase project
`cjnxrkzrmeetzragwrlm`.

## 1. `create-razorpay-order`

The app now sends `"channel": "web"` from the website. When present, after the
normal order is created, also create a Payment Link and a UPI QR and return
their URLs:

```ts
// After `order` is created (Android flow unchanged when channel !== "web")
if (body.channel === "web") {
  const notes = { order_id: order.id, booking_ids: bookingIds.join(","), user_id: String(userId) };
  const auth = `Basic ${btoa(`${keyId}:${keySecret}`)}`;

  const [link, qr] = await Promise.all([
    fetch("https://api.razorpay.com/v1/payment_links", {
      method: "POST",
      headers: { Authorization: auth, "Content-Type": "application/json" },
      body: JSON.stringify({
        amount: order.amount,
        currency: "INR",
        accept_partial: false,
        description: "PhysioConnect session booking",
        customer: { contact: patientPhone },
        notify: { sms: false, email: false },
        reminder_enable: false,
        upi_link: false,          // true = UPI-only link (no card page)
        expire_by: Math.floor(Date.now() / 1000) + 30 * 60,
        notes,
        // Keep doctor payouts (Route) working for link payments:
        // options: { order: { transfers: sameTransfersAsTheOrder } },
      }),
    }).then((r) => (r.ok ? r.json() : null)).catch(() => null),
    fetch("https://api.razorpay.com/v1/payments/qr_codes", {
      method: "POST",
      headers: { Authorization: auth, "Content-Type": "application/json" },
      body: JSON.stringify({
        type: "upi_qr",
        name: "PhysioConnect",
        usage: "single_use",
        fixed_amount: true,
        payment_amount: order.amount,
        description: "PhysioConnect session booking",
        close_by: Math.floor(Date.now() / 1000) + 30 * 60,
        notes,
      }),
    }).then((r) => (r.ok ? r.json() : null)).catch(() => null),
  ]);

  // Save link.id / qr.id against the bookings (e.g. bookings.notes or a new
  // column), so verify-razorpay-payment can look them up.
  await saveWebPaymentRefs(bookingIds, { paymentLinkId: link?.id, qrCodeId: qr?.id });

  response.paymentLinkUrl = link?.short_url ?? null;
  response.qrCodeUrl = qr?.image_url ?? null;
}
```

Response fields read by the app (`CreateRazorPayOrderModel`):
`paymentLinkUrl` and `qrCodeUrl` (snake_case `payment_link_url` / `qr_code_url` also accepted).

## 2. `verify-razorpay-payment`: add `checkStatusOnly`

The website polls every 3 s with:

```json
{ "bookingIds": [12, 13], "userId": 5, "razorpayOrderId": "order_…", "checkStatusOnly": true }
```

When `checkStatusOnly` is true:

1. **Never** record a failure or change bookings to failed. This call is a read.
2. If the bookings are already paid → `{ "success": true, "status": "SUCCESS", "alreadyPaid": true }`.
3. Otherwise fetch the saved link / QR from Razorpay:
   - `GET /v1/payment_links/{id}` → `status === "paid"` → take `payments[0].payment_id`
   - `GET /v1/payments/qr_codes/{id}/payments` → first item with `status === "captured"`
4. If paid: run the **same "mark bookings paid" code** used after a successful
   signature check (payment id, order id, doctor transfer / fund hold), then
   return `{ "success": true, "status": "SUCCESS" }`.
5. If the link is `expired`/`cancelled` → `{ "success": false, "status": "FAILED" }`.
6. Otherwise → `{ "success": false, "status": "PENDING" }`.

Make step 4 idempotent (polling and a webhook may both see the payment).

## 3. Recommended: webhook

Subscribe the existing (or a new) webhook to `payment_link.paid` and
`qr_code.credited`, verify `X-Razorpay-Signature`, and mark the bookings from
`notes.booking_ids` paid with the same idempotent code. Then bookings are
confirmed even if the user closes the browser tab right after paying.

## 4. Doctor payouts (Route)

Payment Link / QR payments create **their own** Razorpay order, so transfers
configured on the original order do not apply. Either pass the transfers in
the link's `options.order.transfers`, or create the transfer after capture
(`POST /v1/payments/{payment_id}/transfers`) in step 4. QR codes don't support
transfers at creation, so use the post-capture transfer for them.
