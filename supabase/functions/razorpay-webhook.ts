// Razorpay webhook: the server-side safety net for payment status.
//
// Confirms or fails bookings even when the patient closes the app / browser
// tab right after paying, loses network before the app verifies, or pays a
// website link later. Works for every channel:
//   - Android app (native Checkout on our order)
//   - Website Payment Link / UPI QR
//
// Subscribe (Razorpay Dashboard -> Settings -> Webhooks, test AND live mode):
//   payment.captured, payment.failed, order.paid,
//   payment_link.paid, qr_code.credited
// with secret RAZORPAY_WEBHOOK_SECRET. Deploy with `--no-verify-jwt`
// (Razorpay doesn't send a Supabase JWT); the signature check is the auth.
//
// Bookings are found by our Razorpay order id (bookings.orderId), which works
// for orders created before this function existed. Success is confirmed via
// verify-razorpay-payment (checkStatusOnly), which re-reads the payment from
// Razorpay, so the webhook payload itself is never trusted for "paid".
import { createClient } from "npm:@supabase/supabase-js@2";
import { createHmac, timingSafeEqual } from "node:crypto";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const secret = Deno.env.get("RAZORPAY_WEBHOOK_SECRET")?.trim();
  if (!secret) return json({ error: "Webhook secret not configured" }, 500);

  const raw = await req.text();
  const signature = req.headers.get("x-razorpay-signature") ?? "";
  const expected = createHmac("sha256", secret).update(raw).digest("hex");
  const a = new TextEncoder().encode(expected);
  const b = new TextEncoder().encode(signature);
  if (a.length !== b.length || !timingSafeEqual(a, b)) {
    return json({ error: "Invalid signature" }, 401);
  }

  const event = JSON.parse(raw);
  const type = String(event?.event ?? "");
  const payload = event?.payload ?? {};
  const payment = payload?.payment?.entity ?? null;

  // Our order id: the payment's own order (app checkout), or the order we
  // wrote into the link / QR notes (website).
  let orderId: string | null = null;
  let failureMessage: string | null = null;
  switch (type) {
    case "payment.captured":
    case "order.paid":
      orderId = payload?.order?.entity?.id ?? payment?.order_id ?? null;
      if (!orderId || !(await hasBookings(orderId))) orderId = payment?.notes?.order_id ?? orderId;
      break;
    case "payment_link.paid":
      orderId = payload?.payment_link?.entity?.notes?.order_id ?? payment?.notes?.order_id ?? null;
      break;
    case "qr_code.credited":
      orderId = payload?.qr_code?.entity?.notes?.order_id ?? payment?.notes?.order_id ?? null;
      break;
    case "payment.failed":
      orderId = payment?.order_id ?? null;
      if (!orderId || !(await hasBookings(orderId))) orderId = payment?.notes?.order_id ?? orderId;
      failureMessage = String(
        payment?.error_description ?? payment?.error_reason ?? "Payment failed",
      ).slice(0, 300);
      break;
    default:
      return json({ ignored: type });
  }
  if (!orderId) return json({ ignored: "no order id" });

  const supabase = client();
  const { data: bookings, error } = await supabase
    .from("bookings")
    .select(`id, "userId", "paymentStatus"`)
    .eq("orderId", orderId);
  if (error) return json({ error: "Booking lookup failed" }, 500); // Razorpay retries
  if (!bookings?.length) return json({ ignored: "no bookings for order" });

  const bookingIds = bookings.map((row: any) => row.id);
  const userId = bookings[0].userId;

  if (type === "payment.failed") {
    // A failed attempt doesn't end the booking: the patient can retry, and a
    // later capture on the same order still confirms it. Record the reason
    // only while the booking is unpaid.
    await supabase
      .from("bookings")
      .update({ paymentFailureReason: failureMessage })
      .in("id", bookingIds)
      .neq("paymentStatus", "paid")
      .neq("paymentStatus", "refunded");
    return json({ ok: true, status: "FAILED_ATTEMPT_RECORDED" });
  }

  if (bookings.every((row: any) => row.paymentStatus === "paid")) {
    return json({ ok: true, status: "SUCCESS", alreadyPaid: true });
  }

  const { data, error: verifyError } = await supabase.functions.invoke("verify-razorpay-payment", {
    body: { bookingIds, userId, checkStatusOnly: true },
  });
  if (verifyError) return json({ error: "Confirmation failed" }, 500); // Razorpay retries
  return json({ ok: true, status: data?.status ?? null });
});

function client() {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const secretKeys = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS")!);
  return createClient(supabaseUrl, secretKeys["default"]);
}

async function hasBookings(orderId: string): Promise<boolean> {
  const { data } = await client().from("bookings").select("id").eq("orderId", orderId).limit(1);
  return (data?.length ?? 0) > 0;
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: { "Content-Type": "application/json" } });
}
