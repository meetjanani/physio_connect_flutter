import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (req.method !== "POST") return jsonResponse({ error: "Method not allowed" }, 405);

    const { bookingId, doctorId } = await req.json();

    if (!bookingId || !doctorId) {
      return jsonResponse({ error: "bookingId and doctorId are required" }, 400);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const secretKeys = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS")!);
    const supabaseSecretKey = secretKeys["default"];
    const supabase = createClient(supabaseUrl, supabaseSecretKey);

    // 1. Fetch the SINGLE booking row
    const { data: booking, error: bookingError } = await supabase
      .from("bookings")
      .select(`
        id,
        "doctorId",
        "paymentId",
        price,
        "paymentStatus",
        "paymentVerifiedAt"
      `)
      .eq("id", bookingId)
      .single();

    if (bookingError || !booking) {
      console.error("Booking fetch error:", bookingError);
      return jsonResponse({ error: "Booking not found" }, 404);
    }

    // 2. Security Check
    if (String(booking.doctorId) !== String(doctorId)) {
      return jsonResponse({ error: "Not authorized to refund this booking" }, 403);
    }
    if (booking.paymentStatus === "refunded") {
      return jsonResponse({ error: "Booking is already refunded" }, 400);
    }
    if (booking.paymentStatus !== "paid" || !booking.paymentId) {
      return jsonResponse({ error: "Booking is not in a paid state or missing paymentId" }, 400);
    }

    // 3. Time Limit Check: Must be within 48 hours of payment
    const paymentDate = new Date(booking.paymentVerifiedAt);
    const currentDate = new Date();
    const hoursDifference = (currentDate.getTime() - paymentDate.getTime()) / (1000 * 60 * 60);

    if (hoursDifference > 48) {
      return jsonResponse({ error: "Refund window (48 hours) has expired for this booking." }, 400);
    }

    const razorpayKeyId = Deno.env.get("RAZORPAY_KEY_ID")!;
    const razorpayKeySecret = Deno.env.get("RAZORPAY_KEY_SECRET")!;
    const basicAuth = btoa(`${razorpayKeyId}:${razorpayKeySecret}`);

    // =======================================================================
    // PARTIAL REFUND MAGIC HAPPENS HERE:
    // booking.price is the price of THIS specific session (e.g., ₹500),
    // NOT the total bulk payment amount (e.g., ₹2500).
    // =======================================================================
    const amountPaise = Math.round(Number(booking.price) * 100);

    const refundResponse = await fetch(
      `https://api.razorpay.com/v1/payments/${booking.paymentId}/refund`,
      {
        method: "POST",
        headers: {
          Authorization: `Basic ${basicAuth}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          amount: amountPaise, // Sending an amount less than the original payment triggers a Partial Refund
          reverse_all: 1,      // Razorpay proportionally claws back 85% from doctor and 15% from you
        }),
      }
    );

    const refundData = await refundResponse.json();

    if (!refundResponse.ok) {
      console.error("Razorpay refund error:", refundData);
      return jsonResponse({ error: "Razorpay failed to process refund", details: refundData }, 500);
    }

    // =======================================================================
    // UPDATE SINGLE ROW:
    // Because we use .eq("id", booking.id), this only marks this specific
    // appointment as refunded. The other 4 bulk appointments remain "paid".
    // =======================================================================
    const { error: updateError } = await supabase
      .from("bookings")
      .update({
        "paymentStatus": "refunded",
        "bookingStatus": "refunded",
        "razorpayRefundId": refundData.id
      })
      .eq("id", booking.id);

    if (updateError) {
      console.error("Failed to update booking status:", updateError);
      return jsonResponse({ error: "Refund processed at Razorpay, but DB update failed" }, 500);
    }

    return jsonResponse({
      success: true,
      message: "Refund initiated successfully",
      refundId: refundData.id,
    });

  } catch (error) {
    console.error("Unexpected error:", error);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}