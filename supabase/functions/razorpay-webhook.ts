// Razorpay webhook for website payments (Payment Link + UPI QR).
//
// Confirms the booking even if the patient closes the browser tab right after
// paying. Subscribe the webhook to `payment_link.paid` and `qr_code.credited`
// with secret RAZORPAY_WEBHOOK_SECRET. Deploy with `--no-verify-jwt`
// (Razorpay doesn't send a Supabase JWT); the signature check below is the auth.
//
// The bookings come from the link / QR `notes` set by create-razorpay-order;
// confirmation reuses verify-razorpay-payment (checkStatusOnly), which looks
// the payment up on Razorpay again, so this function never trusts the payload.
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
  if (type !== "payment_link.paid" && type !== "qr_code.credited") {
    return json({ ignored: type });
  }

  const entity = type === "payment_link.paid"
    ? event?.payload?.payment_link?.entity
    : event?.payload?.qr_code?.entity;
  const notes = entity?.notes ?? {};
  const bookingIds = String(notes.booking_ids ?? "")
    .split(",")
    .map((id) => Number(id.trim()))
    .filter((id) => Number.isInteger(id) && id > 0);
  const userId = notes.user_id;
  if (!bookingIds.length || !userId) return json({ ignored: "no booking notes" });

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const secretKeys = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS")!);
  const supabase = createClient(supabaseUrl, secretKeys["default"]);

  const { data, error } = await supabase.functions.invoke("verify-razorpay-payment", {
    body: { bookingIds, userId, checkStatusOnly: true },
  });
  if (error) return json({ error: "Confirmation failed" }, 500); // Razorpay retries
  return json({ ok: true, status: data?.status ?? null });
});

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: { "Content-Type": "application/json" } });
}
