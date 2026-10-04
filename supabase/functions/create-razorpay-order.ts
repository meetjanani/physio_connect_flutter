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
      console.error("Booking fetch error:", bookingsError);
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
      console.error("Doctor error:", doctorError);
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
      console.error("FATAL: Razorpay keys are missing in the environment!");
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
      console.log("Returning existing order:", bookings[0].orderId);
      return jsonResponse({
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

    console.log("SENDING TO RAZORPAY:", {
      amountPaise,
      receiptString,
      isBulkAppointment,
      doctorAccountId: doctor.razorpayAccountId,
      keyIdLength: razorpayKeyId.length,
    });

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
      console.error("Razorpay error:", razorpayData);
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
      console.error("Database update error:", updateError);
      return jsonResponse({ error: "Unable to save payment information to database" }, 500);
    }

    // -----------------------------------------
    // 12. Return order to Flutter
    // -----------------------------------------
    return jsonResponse({
      success: true,
      orderId: razorpayData.id,
      amount: amountPaise,
      currency: "INR",
      keyId: razorpayKeyId,
      doctorAmount: doctorAmountPaise,
      platformFeeAmount: platformFeePaise,
    });
  } catch (error) {
    console.error("Unexpected error:", error);
    return jsonResponse({ error: error instanceof Error ? error.message : String(error) }, 500);
  }
});

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