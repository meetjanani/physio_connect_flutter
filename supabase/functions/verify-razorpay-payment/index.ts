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
    const { bookingIds, userId, razorpayOrderId, razorpayPaymentId, razorpaySignature, paymentFailure, checkStatusOnly } = body;

    if (!bookingIds || !Array.isArray(bookingIds) || bookingIds.length === 0) {
      return jsonResponse({ error: "bookingIds array is required" }, 400);
    }
    if (!userId) return jsonResponse({ error: "userId is required" }, 400);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const secretKeys = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS")!);
    const supabase = createClient(supabaseUrl, secretKeys["default"]);

    // Website (Payment Link / UPI QR): read-only status poll. Never records a
    // failure; marks the bookings paid only once Razorpay reports a captured
    // payment for the link / QR saved by create-razorpay-order.
    if (checkStatusOnly === true) {
      return await checkWebPaymentStatus(supabase, { bookingIds, userId });
    }

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

  } catch (_error) {
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
  } catch (_err) {
  }

  // TypeScript fix applied here: Record
  const updatePayload: Record<string, unknown> = {
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

  const { error: finalUpdateError } = await supabase
    .from("bookings")
    .update(updatePayload)
    .in("id", bookingIds)
    .neq("paymentStatus", "refunded");
  if (finalUpdateError) return jsonResponse({ error: "Booking final status update failed" }, 500);

  // Invoke Google Meet Edge Function Async
  let meetResults: any[] = [];
  try {
    const { data, error: invokeError } = await supabase.functions.invoke("create-meet-for-booking", {
      body: { bookingIds, userId },
    });
    if (invokeError) throw invokeError;
    meetResults = data?.results || [];
  } catch (_meetError) {
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

async function checkWebPaymentStatus(supabase: any, { bookingIds, userId }: any) {
  const loaded = await loadOwnedBookings(supabase, bookingIds, userId);
  if (loaded.response) return loaded.response;

  if (loaded.bookings.every((b: any) => b.paymentStatus === "paid")) {
    return jsonResponse({ success: true, status: "SUCCESS", alreadyPaid: true });
  }

  const rawKeyId = Deno.env.get("RAZORPAY_KEY_ID")?.trim();
  const rawKeySecret = Deno.env.get("RAZORPAY_KEY_SECRET")?.trim();
  if (!rawKeyId || !rawKeySecret) throw new Error("Razorpay credentials missing");
  const basicAuth = btoa(`${rawKeyId}:${rawKeySecret}`);
  const get = async (url: string) => {
    try {
      const r = await fetch(url, { headers: { Authorization: `Basic ${basicAuth}` } });
      return r.ok ? await r.json() : null;
    } catch (_) {
      return null;
    }
  };

  const expectedAmountPaise = Math.round(
    loaded.bookings.reduce((sum: number, b: any) => sum + (Number(b.price) || 0), 0) * 100,
  );
  // Link / QR ids were saved in the Razorpay order notes by create-razorpay-order.
  const orderId = loaded.bookings.find((b: any) => b.orderId)?.orderId;
  if (!orderId) return jsonResponse({ success: false, status: "PENDING" });
  const order = await get(`https://api.razorpay.com/v1/orders/${orderId}`);
  const notes = (order?.notes && !Array.isArray(order.notes)) ? order.notes : {};
  const linkId = notes.web_payment_link_id || null;
  const qrId = notes.web_qr_code_id || null;
  const isCaptured = (p: any) => p?.status === "captured";

  let paymentId: string | null = null;
  let linkClosed = !linkId;
  let qrClosed = !qrId;

  // 1. Paid on the order itself (embedded checkout, or an earlier attempt).
  const orderPayments = await get(`https://api.razorpay.com/v1/orders/${orderId}/payments`);
  paymentId = (orderPayments?.items ?? []).find(isCaptured)?.id ?? null;

  // 2. Payment Link.
  if (!paymentId && linkId) {
    const link = await get(`https://api.razorpay.com/v1/payment_links/${linkId}`);
    if (link?.status === "paid") {
      paymentId = (link.payments ?? []).find(isCaptured)?.payment_id ?? link.payments?.[0]?.payment_id ?? null;
    }
    linkClosed = link?.status === "expired" || link?.status === "cancelled";
  }

  // 3. UPI QR.
  if (!paymentId && qrId) {
    const list = await get(`https://api.razorpay.com/v1/payments/qr_codes/${qrId}/payments`);
    paymentId = (list?.items ?? []).find(isCaptured)?.id ?? null;
    if (!paymentId) {
      const qr = await get(`https://api.razorpay.com/v1/payments/qr_codes/${qrId}`);
      qrClosed = qr?.status === "closed";
    }
  }

  // 4. Recent payments carrying this order in their notes (as GIFT City
  //    Carpool does), in case the ids couldn't be saved on the order.
  if (!paymentId) {
    const recent = await get("https://api.razorpay.com/v1/payments?count=25");
    paymentId = (recent?.items ?? []).find(
      (p: any) => isCaptured(p) && p.notes?.order_id === String(orderId),
    )?.id ?? null;
  }

  if (!paymentId) {
    return jsonResponse({ success: false, status: linkClosed && qrClosed ? "FAILED" : "PENDING" });
  }

  const paymentData = await fetchRazorpayPayment(paymentId, basicAuth);
  if (paymentData.response) return paymentData.response;
  const payment = paymentData.payment;
  if (payment.status !== "captured" || Number(payment.amount) !== expectedAmountPaise) {
    return jsonResponse({ success: false, status: "PENDING", error: "Payment could not be matched" });
  }

  // Link / QR payments have no Route transfer, so create the doctor's held
  // transfer after capture (same split as the original order). No-op when
  // the payment already has one.
  await ensureDoctorTransfer(supabase, { bookingIds, paymentId, basicAuth });

  const marked = await markBookingsPaid(supabase, {
    bookingIds,
    userId,
    razorpayPaymentId: paymentId,
    razorpayOrderId: orderId,
    razorpaySignature: null,
    basicAuth,
    amount: payment.amount,
  });
  if (marked.status !== 200) return marked;
  return jsonResponse({ success: true, status: "SUCCESS", paymentId });
}

async function ensureDoctorTransfer(supabase: any, { bookingIds, paymentId, basicAuth }: any) {
  try {
    const existing = await fetch(`https://api.razorpay.com/v1/payments/${paymentId}/transfers`, {
      headers: { Authorization: `Basic ${basicAuth}` },
    }).then((r) => (r.ok ? r.json() : null));
    if (existing?.items?.length) return;

    const { data: rows } = await supabase
      .from("bookings")
      .select(`"doctorId", "doctorAmount"`)
      .in("id", bookingIds);
    if (!rows?.length) return;
    const doctorAmountPaise = Math.round(
      rows.reduce((sum: number, r: any) => sum + (Number(r.doctorAmount) || 0), 0) * 100,
    );
    const { data: doctor } = await supabase
      .from("doctor")
      .select(`"razorpayAccountId"`)
      .eq("userId", rows[0].doctorId)
      .single();
    if (!doctor?.razorpayAccountId || doctorAmountPaise <= 0) return;

    await fetch(`https://api.razorpay.com/v1/payments/${paymentId}/transfers`, {
      method: "POST",
      headers: { Authorization: `Basic ${basicAuth}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        transfers: [{ account: doctor.razorpayAccountId, amount: doctorAmountPaise, currency: "INR", on_hold: 1 }],
      }),
    });
  } catch (_err) {
  }
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

  const { error: _failureUpdateError } = await supabase.from("bookings").update({
    paymentFailureReason: failureMessage,
    orderId: razorpayOrderId ?? null,
    paymentId: razorpayPaymentId ?? null,
  }).in("id", bookingIds).neq("paymentStatus", "paid").neq("paymentStatus", "refunded");

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