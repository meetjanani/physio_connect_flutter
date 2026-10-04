import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    if (req.method !== "POST") return jsonResponse({ error: "Method not allowed" }, 405);

    const { bookingIds, doctorId } = await req.json();

    if (!bookingIds || !Array.isArray(bookingIds) || bookingIds.length === 0) {
      return jsonResponse({ error: "bookingIds array is required" }, 400);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const secretKeys = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS")!);
    const supabaseSecretKey = secretKeys["default"];
    const supabase = createClient(supabaseUrl, supabaseSecretKey);

    // 1. Fetch the bookings to verify status and get the Transfer ID
    const { data: bookings, error: bookingsError } = await supabase
      .from("bookings")
      .select(`id, "doctorId", "bookingStatus", "razorpayTransferId", "transferStatus"`)
      .in("id", bookingIds);

    if (bookingsError || !bookings || bookings.length === 0) {
      return jsonResponse({ error: "Bookings not found" }, 404);
    }

    // 2. Strict Security Validations
    const transferId = bookings[0].razorpayTransferId;
    if (!transferId) {
      return jsonResponse({ error: "No Razorpay transfer ID found for these bookings" }, 400);
    }

    for (const booking of bookings) {
      if (String(booking.doctorId) !== String(doctorId)) {
        return jsonResponse({ error: `Doctor not authorized for booking ${booking.id}` }, 403);
      }
      // Ensure every session in the package is either completed or refunded
      if (booking.bookingStatus !== "completed" && booking.bookingStatus !== "refunded") {
        return jsonResponse({ error: "Cannot release payment: Not all sessions are completed yet." }, 400);
      }
      if (booking.transferStatus === "released") {
        return jsonResponse({ success: true, message: "Payment already released" });
      }
    }

    // 3. Setup Razorpay Keys
    const razorpayKeyId = Deno.env.get("RAZORPAY_KEY_ID");
    const razorpayKeySecret = Deno.env.get("RAZORPAY_KEY_SECRET");
    if (!razorpayKeyId || !razorpayKeySecret) throw new Error("Razorpay credentials missing");

    const basicAuth = btoa(`${razorpayKeyId}:${razorpayKeySecret}`);

    // 4. Trigger Razorpay to Release the Hold
    const releaseResponse = await fetch(`https://api.razorpay.com/v1/transfers/${transferId}`, {
      method: "PATCH",
      headers: {
        Authorization: `Basic ${basicAuth}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        on_hold: 0 // 0 tells Razorpay to release the money to the doctor immediately
      }),
    });

    const releaseData = await releaseResponse.json();

    if (!releaseResponse.ok) {
      console.error("Razorpay release error:", releaseData);
      return jsonResponse({ error: "Razorpay failed to release payment", details: releaseData }, 500);
    }

    // 5. Update Database to mark transfer as released
    const { error: updateError } = await supabase
      .from("bookings")
      .update({ transferStatus: "released" })
      .in("id", bookingIds);

    if (updateError) {
      console.error("DB Update Error:", updateError);
      return jsonResponse({ error: "Payment released, but DB update failed" }, 500);
    }

    return jsonResponse({
      success: true,
      message: "Funds successfully released to the doctor's account.",
      transferId: transferId
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