import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  // -----------------------------------------
  // CORS
  // -----------------------------------------
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  try {
    // -----------------------------------------
    // 1. Validate HTTP method
    // -----------------------------------------
    if (req.method !== "POST") {
      return jsonResponse({ error: "Method not allowed" }, 405);
    }

    // -----------------------------------------
    // 2. Request body
    // -----------------------------------------
    const body = await req.json();

    const bookingIds = body.bookingIds;
    const userId = body.userId;
    const isBulkAppointment = body.isBulkAppointment ?? false;
    const bulkAppointmentId = body.bulkAppointmentId;
    // Website checkout: also return a Payment Link + UPI QR (see webPaymentOptions).
    const isWeb = body.channel === "web";

    if (!bookingIds || !Array.isArray(bookingIds) || bookingIds.length === 0) {
      return jsonResponse({ error: "bookingIds array is required and cannot be empty" }, 400);
    }

    if (!userId) {
      return jsonResponse({ error: "userId is required" }, 400);
    }

    if (isBulkAppointment && !bulkAppointmentId) {
      return jsonResponse({ error: "bulkAppointmentId is required when isBulkAppointment is true" }, 400);
    }

    // -----------------------------------------
    // 3. Supabase Setup
    // -----------------------------------------
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseSecretKeysRaw = Deno.env.get("SUPABASE_SECRET_KEYS");

    if (!supabaseUrl || !supabaseSecretKeysRaw) {
      throw new Error("Supabase environment variables are not configured");
    }

    const secretKeys = JSON.parse(supabaseSecretKeysRaw);
    const supabaseSecretKey = secretKeys["default"];

    const supabase = createClient(supabaseUrl, supabaseSecretKey);

    // -----------------------------------------
    // 4. Get ALL bookings in the cart
    // -----------------------------------------
    const { data: bookings, error: bookingsError } = await supabase
      .from("bookings")
      .select(`
        id,
        userId,
        doctorId,
        price,
        paymentStatus,
        orderId,
        paymentId,
        signature
      `)
      .in("id", bookingIds);

    if (bookingsError || !bookings || bookings.length === 0) {
      return jsonResponse({ error: "Bookings not found" }, 404);
    }

    if (bookings.length !== bookingIds.length) {
      return jsonResponse({ error: "One or more bookings could not be found" }, 404);
    }

    // -----------------------------------------
    // 5. Verify Ownership & State
    // -----------------------------------------
    const firstDoctorId = bookings[0].doctorId;

    for (const booking of bookings) {
      if (String(booking.userId) !== String(userId)) {
        return jsonResponse({ error: `Not authorized to pay for booking ${booking.id}` }, 403);
      }
      if (booking.paymentStatus === "paid") {
        return jsonResponse({ error: `Booking ${booking.id} is already paid` }, 400);
      }
      if (booking.doctorId !== firstDoctorId) {
        return jsonResponse({ error: "All bookings in a single checkout must belong to the same doctor" }, 400);
      }
    }

    // -----------------------------------------
    // 6. Get doctor details
    // -----------------------------------------
    const { data: doctor, error: doctorError } = await supabase
      .from("doctor")
      .select(`
        id,
        name,
        isActive,
        percentageSplit,
        razorpayAccountId,
        razorpayAccountStatus
      `)
      .eq("userId", firstDoctorId)
      .single();

    if (doctorError || !doctor) {
      return jsonResponse({ error: "Doctor not found" }, 404);
    }

    if (!doctor.isActive || doctor.razorpayAccountStatus !== "active") {
      return jsonResponse({ error: "Doctor is unavailable or Razorpay account is inactive" }, 400);
    }

    // -----------------------------------------
    // 7. Calculate TOTAL amount for the cart
    // -----------------------------------------
    let totalPriceRupees = 0;
    for (const booking of bookings) {
      const price = Number(booking.price);
      if (!Number.isFinite(price) || price <= 0) {
        return jsonResponse({ error: `Invalid price for booking ${booking.id}` }, 400);
      }
      totalPriceRupees += price;
    }

    const amountPaise = Math.round(totalPriceRupees * 100);

    const splitPercent = (typeof doctor.percentageSplit === 'number' && doctor.percentageSplit >= 0 && doctor.percentageSplit <= 100)
      ? doctor.percentageSplit
      : 85;

    // Dynamic percentage applied to the TOTAL cart sum
    const doctorAmountPaise = Math.floor(amountPaise * (splitPercent / 100));
    const platformFeePaise = amountPaise - doctorAmountPaise;

    // -----------------------------------------
    // 8. Razorpay credentials
    // -----------------------------------------
    const rawKeyId = Deno.env.get("RAZORPAY_KEY_ID");
    const rawKeySecret = Deno.env.get("RAZORPAY_KEY_SECRET");

    if (!rawKeyId || !rawKeySecret) {
      return jsonResponse({ error: "Server configuration error: Missing Razorpay keys" }, 500);
    }

    const razorpayKeyId = rawKeyId.trim();
    const razorpayKeySecret = rawKeySecret.trim();
    const basicAuth = btoa(`${razorpayKeyId}:${razorpayKeySecret}`);

    // -----------------------------------------
    // 9. Existing Razorpay order check
    // -----------------------------------------
    // Moved down so we can return the calculated amounts and keyId
    if (bookings[0].orderId) {
      const web = isWeb
        ? await webPaymentOptions({
            basicAuth, bookingIds, userId, amountPaise,
            orderId: bookings[0].orderId,
            contact: body.contact,
          })
        : {};
      return jsonResponse({
        ...web,
        success: true,
        orderId: bookings[0].orderId,
        amount: amountPaise,
        currency: "INR",
        keyId: razorpayKeyId,
        doctorAmount: doctorAmountPaise,
        platformFeeAmount: platformFeePaise,
        message: "Existing Razorpay order returned",
      });
    }

    // -----------------------------------------
    // 10. Create Razorpay Order
    // -----------------------------------------
    const receiptString = isBulkAppointment
      ? `bulk_${bulkAppointmentId.substring(0, 30)}`
      : `bk_${bookingIds[0]}`;

    const razorpayResponse = await fetch("https://api.razorpay.com/v1/orders", {
      method: "POST",
      headers: {
        Authorization: `Basic ${basicAuth}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        amount: amountPaise,
        currency: "INR",
        receipt: receiptString,
        partial_payment: false,
        // Lets the webhook / support trace a payment back to its bookings.
        notes: { booking_ids: bookingIds.join(","), user_id: String(userId) },
        transfers: [
          {
            account: doctor.razorpayAccountId,
            amount: doctorAmountPaise,
            currency: "INR",
            on_hold: 1,
          },
        ],
      }),
    });

    const razorpayData = await razorpayResponse.json();

    if (!razorpayResponse.ok) {
      return jsonResponse({ error: "Razorpay order creation failed", razorpay: razorpayData, status: razorpayResponse.status }, 500);
    }

    // -----------------------------------------
    // 11. Save payment information to ALL rows
    // -----------------------------------------
    const averageDoctorAmountRupees = (doctorAmountPaise / 100) / bookings.length;
    const averagePlatformFeeRupees = (platformFeePaise / 100) / bookings.length;

    const { error: updateError } = await supabase
      .from("bookings")
      .update({
        orderId: razorpayData.id,
        doctorAmount: averageDoctorAmountRupees,
        platformFeeAmount: averagePlatformFeeRupees,
        paymentStatus: "created",
        isBulkAppointment: isBulkAppointment,
        bulkAppointmentId: isBulkAppointment ? bulkAppointmentId : null
      })
      .in("id", bookingIds);

    if (updateError) {
      return jsonResponse({ error: "Unable to save payment information to database" }, 500);
    }

    // -----------------------------------------
    // 12. Return order to Flutter
    // -----------------------------------------
    const web = isWeb
      ? await webPaymentOptions({
          basicAuth, bookingIds, userId, amountPaise,
          orderId: razorpayData.id,
          contact: body.contact,
        })
      : {};
    return jsonResponse({
      ...web,
      success: true,
      orderId: razorpayData.id,
      amount: amountPaise,
      currency: "INR",
      keyId: razorpayKeyId,
      doctorAmount: doctorAmountPaise,
      platformFeeAmount: platformFeePaise,
    });
  } catch (error) {
    return jsonResponse({ error: error instanceof Error ? error.message : String(error) }, 500);
  }
});

// -----------------------------------------
// Website: Payment Link + UPI QR (same approach as GIFT City Carpool)
// -----------------------------------------
// Razorpay has not approved the website domain for embedded Checkout, so the
// website pays on a Razorpay-hosted Payment Link, or by scanning a UPI QR.
// Neither needs website approval.
//
// No database columns are needed: the link / QR ids are stored in the
// Razorpay order's notes, where verify-razorpay-payment (checkStatusOnly)
// reads them back. The doctor's held transfer is created after capture.
//
// Failures never block the order. If neither can be created the Razorpay
// reason is returned as `webPaymentError` so the website can show it.
async function webPaymentOptions(
  { basicAuth, bookingIds, userId, amountPaise, orderId, contact = null }: any,
): Promise<{ paymentLinkUrl: string | null; qrCodeUrl: string | null; webPaymentError?: string }> {
  const headers = { Authorization: `Basic ${basicAuth}`, "Content-Type": "application/json" };
  const notes = { order_id: String(orderId), booking_ids: bookingIds.join(","), user_id: String(userId) };
  const description = bookingIds.length > 1
    ? `PhysioConnect - ${bookingIds.length} sessions`
    : "PhysioConnect session booking";
  const errors: string[] = [];

  const call = async (method: string, url: string, payload?: unknown) => {
    try {
      const r = await fetch(url, { method, headers, body: payload ? JSON.stringify(payload) : undefined });
      const data = await r.json().catch(() => null);
      if (!r.ok) {
        const reason = data?.error?.description ?? data?.error?.reason ?? `HTTP ${r.status}`;
        console.warn("razorpay", method, url, r.status, JSON.stringify(data));
        return { ok: false, data: null, reason: String(reason) };
      }
      return { ok: true, data, reason: null };
    } catch (e) {
      return { ok: false, data: null, reason: e instanceof Error ? e.message : String(e) };
    }
  };

  // Reuse a still-open link / QR for this order (retry, page refresh).
  const order = (await call("GET", `https://api.razorpay.com/v1/orders/${orderId}`)).data;
  const orderNotes = (order?.notes && !Array.isArray(order.notes)) ? order.notes : {};

  let link: any = null;
  if (orderNotes.web_payment_link_id) {
    const existing = (await call("GET", `https://api.razorpay.com/v1/payment_links/${orderNotes.web_payment_link_id}`)).data;
    if (existing?.status === "created" && Number(existing.amount) === amountPaise) link = existing;
  }
  if (!link) {
    const linkBody = (upiLink: boolean) => ({
      amount: amountPaise,
      currency: "INR",
      accept_partial: false,
      description,
      customer: contact ? { contact: String(contact) } : undefined,
      notify: { sms: false, email: false },
      reminder_enable: false,
      notes,
      upi_link: upiLink,
    });
    // UPI link opens the UPI app straight away (as in GIFT City Carpool).
    // Razorpay doesn't offer UPI links in test mode or on some accounts, so
    // fall back to the standard link (UPI, cards, wallets on one page).
    const upi = await call("POST", "https://api.razorpay.com/v1/payment_links", linkBody(true));
    if (upi.ok) {
      link = upi.data;
    } else {
      const standard = await call("POST", "https://api.razorpay.com/v1/payment_links", linkBody(false));
      if (standard.ok) link = standard.data;
      else errors.push(`Payment link: ${standard.reason}`);
    }
  }

  let qr: any = null;
  if (orderNotes.web_qr_code_id) {
    const existing = (await call("GET", `https://api.razorpay.com/v1/payments/qr_codes/${orderNotes.web_qr_code_id}`)).data;
    if (existing?.status === "active" && Number(existing.payment_amount) === amountPaise) qr = existing;
  }
  if (!qr) {
    // Needs the QR Codes feature on the Razorpay account; the website shows a
    // QR of the payment link when this isn't available.
    const created = await call("POST", "https://api.razorpay.com/v1/payments/qr_codes", {
      type: "upi_qr",
      name: "PhysioConnect",
      usage: "single_use",
      fixed_amount: true,
      payment_amount: amountPaise,
      description,
      notes,
    });
    if (created.ok) qr = created.data;
    else errors.push(`QR code: ${created.reason}`);
  }

  // Remember the ids on the order for verify-razorpay-payment.
  if ((link?.id ?? "") !== (orderNotes.web_payment_link_id ?? "") || (qr?.id ?? "") !== (orderNotes.web_qr_code_id ?? "")) {
    const patched = await call("PATCH", `https://api.razorpay.com/v1/orders/${orderId}`, {
      notes: {
        ...orderNotes,
        booking_ids: bookingIds.join(","),
        user_id: String(userId),
        web_payment_link_id: link?.id ?? "",
        web_qr_code_id: qr?.id ?? "",
      },
    });
    if (!patched.ok) errors.push(`Saving link on order: ${patched.reason}`);
  }

  const result: { paymentLinkUrl: string | null; qrCodeUrl: string | null; webPaymentError?: string } = {
    paymentLinkUrl: link?.short_url ?? null,
    qrCodeUrl: qr?.image_url ?? null,
  };
  if (!result.paymentLinkUrl && !result.qrCodeUrl) result.webPaymentError = errors.join("; ");
  return result;
}

// -----------------------------------------
// Helper
// -----------------------------------------
function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}