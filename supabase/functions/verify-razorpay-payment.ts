import { createClient } from "npm:@supabase/supabase-js@2";
import { createHmac } from "node:crypto";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    if (req.method !== "POST") return jsonResponse({ error: "Method not allowed" }, 405);

    const body = await req.json();
    const { bookingIds, userId, razorpayOrderId, razorpayPaymentId, razorpaySignature, paymentFailure } = body;

    if (!bookingIds || !Array.isArray(bookingIds) || bookingIds.length === 0) {
      return jsonResponse({ error: "bookingIds array is required" }, 400);
    }
    if (!userId) return jsonResponse({ error: "userId is required" }, 400);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const secretKeys = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS")!);
    const supabase = createClient(supabaseUrl, secretKeys["default"]);

    const failureMessage = typeof paymentFailure?.message === "string" ? paymentFailure.message.trim() : "";
    if (failureMessage) {
      return await recordPaymentFailure(supabase, { bookingIds, userId, razorpayOrderId, razorpayPaymentId, failureMessage });
    }

    if (!razorpayOrderId) return jsonResponse({ error: "razorpayOrderId is required" }, 400);
    if (!razorpayPaymentId) return jsonResponse({ error: "razorpayPaymentId is required" }, 400);
    if (!razorpaySignature) return jsonResponse({ error: "razorpaySignature is required" }, 400);

    const loaded = await loadOwnedBookings(supabase, bookingIds, userId);
    if (loaded.response) return loaded.response;

    const paidEarly = alreadyPaidResponse(loaded.bookings);
    if (paidEarly) return paidEarly;

    let totalPriceRupees = 0;
    for (const booking of loaded.bookings) {
      const price = Number(booking.price);
      if (!Number.isFinite(price) || price <= 0) return jsonResponse({ error: `Invalid price on booking ${booking.id}` }, 400);
      totalPriceRupees += price;
    }

    const rawKeyId = Deno.env.get("RAZORPAY_KEY_ID")?.trim();
    const rawKeySecret = Deno.env.get("RAZORPAY_KEY_SECRET")?.trim();
    if (!rawKeyId || !rawKeySecret) throw new Error("Razorpay credentials missing");

    const signaturePayload = `${razorpayOrderId}|${razorpayPaymentId}`;

    const expectedSignature = createHmac("sha256", rawKeySecret).update(signaturePayload).digest("hex");

    if (expectedSignature !== razorpaySignature) {
      return jsonResponse({ error: "Invalid Razorpay payment signature" }, 400);
    }

    const basicAuth = btoa(`${rawKeyId.trim()}:${rawKeySecret.trim()}`);

    const paymentData = await fetchRazorpayPayment(razorpayPaymentId, basicAuth);
    if (paymentData.response) return paymentData.response;

    if (paymentData.payment.order_id !== razorpayOrderId) {
      return jsonResponse({ error: "Payment does not belong to the expected order" }, 400);
    }

    const expectedAmountPaise = Math.round(totalPriceRupees * 100);
    if (Number(paymentData.payment.amount) !== expectedAmountPaise) {
      return jsonResponse({ error: "Payment amount mismatch" }, 400);
    }

    if (paymentData.payment.status !== "captured") {
      return jsonResponse({ error: "Payment not captured", paymentStatus: paymentData.payment.status }, 400);
    }

    return await markBookingsPaid(supabase, {
      bookingIds,
      userId,
      razorpayPaymentId,
      razorpayOrderId,
      razorpaySignature,
      basicAuth,
      amount: paymentData.payment.amount,
    });

  } catch (error) {
    console.error("Unexpected error:", error);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});

async function markBookingsPaid(
  supabase: any,
  { bookingIds, userId, razorpayPaymentId, razorpayOrderId, razorpaySignature = null, basicAuth, amount }: any
) {
  let razorpayTransferId: string | null = null;
  let transferStatus: string | null = null;

  try {
    const transferResponse = await fetch(`https://api.razorpay.com/v1/payments/${razorpayPaymentId}/transfers`, {
      method: "GET",
      headers: { Authorization: `Basic ${basicAuth}` },
    });
    if (transferResponse.ok) {
      const transferData = await transferResponse.json();
      if (transferData.items?.length > 0) {
        razorpayTransferId = transferData.items[0].id;
        transferStatus = transferData.items[0].status;
      }
    }
  } catch (err) {
    console.warn("Could not fetch transfer details:", err);
  }

  // TypeScript fix applied here: Record
  const updatePayload: Record = {
    paymentStatus: "paid",
    bookingStatus: "confirmed",
    paymentVerifiedAt: new Date().toISOString(),
    paymentFailureReason: null,
    orderId: razorpayOrderId,
    paymentId: razorpayPaymentId,
    razorpayTransferId,
    transferStatus,
  };
  if (razorpaySignature) updatePayload.signature = razorpaySignature;

  const { error: finalUpdateError } = await supabase.from("bookings").update(updatePayload).in("id", bookingIds);
  if (finalUpdateError) return jsonResponse({ error: "Booking final status update failed" }, 500);

  // Invoke Google Meet Edge Function Async
  let meetResults: any[] = [];
  try {
    const { data, error: invokeError } = await supabase.functions.invoke("create-meet-for-booking", {
      body: { bookingIds, userId },
    });
    if (invokeError) throw invokeError;
    meetResults = data?.results || [];
  } catch (meetError) {
    console.warn("Invoking Google Meet function failed. Can be retried manually.", meetError);
  }

  return jsonResponse({
    success: true,
    message: "Payment verified successfully",
    bookingIds,
    paymentId: razorpayPaymentId,
    orderId: razorpayOrderId,
    transferId: razorpayTransferId,
    amount,
    meetResults,
  });
}

async function recordPaymentFailure(supabase: any, { bookingIds, userId, razorpayOrderId, razorpayPaymentId, failureMessage }: any) {
  const loaded = await loadOwnedBookings(supabase, bookingIds, userId);
  if (loaded.response) return loaded.response;

  const paidEarly = alreadyPaidResponse(loaded.bookings);
  if (paidEarly) return paidEarly;

  for (const booking of loaded.bookings) {
    const bookingStatus = String(booking.bookingStatus ?? "").toLowerCase();
    if (bookingStatus === "confirmed" || bookingStatus === "completed") {
      return jsonResponse({ error: `Booking ${booking.id} can no longer be discarded` }, 409);
    }
  }

  if (razorpayPaymentId) {
    const rawKeyId = Deno.env.get("RAZORPAY_KEY_ID")?.trim();
    const rawKeySecret = Deno.env.get("RAZORPAY_KEY_SECRET")?.trim();
    if (!rawKeyId || !rawKeySecret) throw new Error("Razorpay credentials missing");

    const basicAuth = btoa(`${rawKeyId.trim()}:${rawKeySecret.trim()}`);

    const paymentData = await fetchRazorpayPayment(razorpayPaymentId, basicAuth);
    if (paymentData.response) return paymentData.response;

    if (paymentData.payment.status === "captured") {
      let totalPriceRupees = 0;
      for (const booking of loaded.bookings) {
        totalPriceRupees += Number(booking.price) || 0;
      }
      const expectedAmountPaise = Math.round(totalPriceRupees * 100);
      const orderMatches = !razorpayOrderId || paymentData.payment.order_id === razorpayOrderId;
      if (!orderMatches || Number(paymentData.payment.amount) !== expectedAmountPaise) {
        return jsonResponse({ error: "Captured payment could not be matched" }, 409);
      }
      return await markBookingsPaid(supabase, {
        bookingIds,
        userId,
        razorpayPaymentId,
        razorpayOrderId: paymentData.payment.order_id,
        razorpaySignature: null,
        basicAuth,
        amount: paymentData.payment.amount,
      });
    }
  }

  const { error: failureUpdateError } = await supabase.from("bookings").update({
    paymentFailureReason: failureMessage,
    orderId: razorpayOrderId ?? null,
    paymentId: razorpayPaymentId ?? null,
  }).in("id", bookingIds).neq("paymentStatus", "paid").neq("paymentStatus", "refunded");

  if (failureUpdateError) console.error("Payment failure update error:", failureUpdateError);
  return jsonResponse({ success: false, error: failureMessage, message: failureMessage });
}

async function loadOwnedBookings(supabase: any, bookingIds: any, userId: any) {
  const { data: bookings, error: bookingsError } = await supabase
    .from("bookings")
    .select(`id, "userId", price, "paymentStatus", "bookingStatus", "orderId"`)
    .in("id", bookingIds);

  if (bookingsError || !bookings || bookings.length === 0) return { bookings: [], response: jsonResponse({ error: "Bookings not found" }, 404) };
  if (bookings.length !== bookingIds.length) return { bookings: [], response: jsonResponse({ error: "Bookings missing" }, 404) };

  for (const booking of bookings) {
    if (String(booking.userId) !== String(userId)) return { bookings: [], response: jsonResponse({ error: `Unauthorized` }, 403) };
  }
  return { bookings, response: null };
}

function alreadyPaidResponse(bookings: any) {
  for (const booking of bookings) {
    if (booking.paymentStatus === "paid") {
      return jsonResponse({ success: true, alreadyPaid: true, message: `Payment verified for ${booking.id}` });
    }
  }
  return null;
}

async function fetchRazorpayPayment(razorpayPaymentId: any, basicAuth: any) {
  const response = await fetch(
    `https://api.razorpay.com/v1/payments/${razorpayPaymentId}`,
    {
      method: "GET",
      headers: { Authorization: `Basic ${basicAuth}` },
    },
  );
  const payment = await response.json();
  if (!response.ok) return { payment: null, response: jsonResponse({ error: "Unable to verify payment", razorpay: payment }, 500) };
  return { payment, response: null };
}

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: { ...corsHeaders, "Content-Type": "application/json" } });
}