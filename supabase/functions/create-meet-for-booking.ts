import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token";
const CALENDAR_EVENTS_URL =
  "https://www.googleapis.com/calendar/v3/calendars/primary/events";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const { bookingIds, userId } = body;

    if (
      !bookingIds ||
      !Array.isArray(bookingIds) ||
      bookingIds.length === 0
    ) {
      return jsonResponse({ error: "bookingIds array is required" }, 400);
    }

    if (!userId) {
      return jsonResponse(
        { error: "userId is required for authorization" },
        400
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const secretKeys = JSON.parse(
      Deno.env.get("SUPABASE_SECRET_KEYS")!
    );

    const supabase = createClient(
      supabaseUrl,
      secretKeys["default"]
    );

    const { data: authCheck, error: authError } = await supabase
      .from("bookings")
      .select('id, "userId", "doctorId"')
      .in("id", bookingIds);

    if (authError || !authCheck || authCheck.length === 0) {
      return jsonResponse({ error: "Bookings not found" }, 404);
    }

    for (const row of authCheck) {
      if (
        String(row.userId) !== String(userId) &&
        String(row.doctorId) !== String(userId)
      ) {
        return jsonResponse(
          {
            error: `Not authorized to access booking ${row.id}`,
          },
          403
        );
      }
    }

    const results = await ensureGoogleMeetForBookings(
      supabase,
      bookingIds
    );

    return jsonResponse({
      success: true,
      results,
    });
  } catch (error) {
    console.error("Meet generator error:", error);

    return jsonResponse(
      { error: "Internal server error" },
      500
    );
  }
});

async function ensureGoogleMeetForBookings(
  supabase: any,
  bookingIds: number[]
): Promise<any[]> {
  const results: any[] = [];

  const { data: bookings } = await supabase
    .from("bookings")
    .select(
      "id, sessionTypeJson, timeSlotJson, patientJson, bookingDate, meetingUrl, paymentStatus"
    )
    .in("id", bookingIds);

  if (!bookings) {
    return [{ error: "Could not load bookings" }];
  }

  let accessToken: string | null | undefined;

  for (const booking of bookings) {
    const bookingId = Number(booking.id);

    if (!isOnlineSessionType(booking.sessionTypeJson)) {
      results.push({
        bookingId,
        skipped: "not_online",
      });
      continue;
    }

    if (accessToken === undefined) {
      accessToken = await googleAccessToken();
    }

    if (!accessToken) {
      results.push({
        bookingId,
        skipped: "google_not_configured",
      });
      continue;
    }

    const start = parseSlotDateTime(
      String(booking.bookingDate ?? ""),
      slotTime(booking.timeSlotJson)
    );

    const end = new Date(
      start.getTime() +
        durationMinutes(booking.sessionTypeJson) * 60_000
    );

    const name = patientName(booking.patientJson);
    const session = getSessioninfo(booking.sessionTypeJson);
    const time = slotTime(booking.timeSlotJson);

    const url = await createGoogleMeetEvent({
      accessToken,
      summary: `PhysioConnect · ${name} · ${time}`,
      details: `${session}`,
      start,
      end,
      requestId: `pc-${bookingId}-${Date.now()}`,
    });

    if (!url) {
      results.push({
        bookingId,
        error: "meet_create_failed",
      });
      continue;
    }

    await supabase
      .from("bookings")
      .update({
        meetingUrl: url,
        meetingProvider: "google_meet",
      })
      .eq("id", bookingId);

    results.push({
      bookingId,
      meetingUrl: url,
    });
  }

  return results;
}

function isOnlineSessionType(sessionTypeJson: unknown): boolean {
  const session = parseJsonField(sessionTypeJson);

  return String(session?.mode ?? "")
    .toLowerCase()
    .includes("online");
}

function parseSlotDateTime(
  bookingDate: string,
  slotTime: string
): Date {
  let datePart = String(bookingDate ?? "")
    .split("T")[0]
    .trim();

  if (!datePart) {
    datePart = new Date().toISOString().split("T")[0];
  }

  const match = String(slotTime ?? "")
    .trim()
    .toUpperCase()
    .match(/(\d{1,2}):(\d{2})\s*(AM|PM)?/);

  let hour = 9;
  let minute = 0;

  if (match) {
    hour = Number(match[1]);
    minute = Number(match[2]);

    if (match[3] === "PM" && hour < 12) {
      hour += 12;
    }

    if (match[3] === "AM" && hour === 12) {
      hour = 0;
    }
  }

  const isoString = `${datePart}T${String(hour).padStart(
    2,
    "0"
  )}:${String(minute).padStart(2, "0")}:00+05:30`;

  const result = new Date(isoString);

  if (isNaN(result.getTime())) {
    return new Date();
  }

  return result;
}

function durationMinutes(json: unknown): number {
  const duration = parseJsonField(json)?.duration;

  if (duration === undefined || duration === null) {
    return 45;
  }

  if (typeof duration === "number") {
    return duration > 0 ? duration : 45;
  }

  const match = String(duration).match(/\d+(?:\.\d+)?/);

  if (!match) {
    return 45;
  }

  const minutes = Number(match[0]);

  return minutes > 0 ? minutes : 45;
}

function patientName(json: unknown): string {
  return String(parseJsonField(json)?.name ?? "Patient");
}

function slotTime(json: unknown): string {
  return String(parseJsonField(json)?.time ?? "09:00");
}

function getSessioninfo(json: unknown): string {
  let sessionName = String(parseJsonField(json)?.name ?? "Session Name");
  let sessionDescription = String(parseJsonField(json)?.description ?? "Session description");
  let sessionDuration = String(parseJsonField(json)?.duration ?? "Session description");
  let newLine = "\n"
  return String(sessionName + newLine + sessionDescription + newLine + sessionDuration);
}

function parseJsonField(
  value: unknown
): Record<string, any> | null {
  if (typeof value === "object" && value !== null) {
    return value as Record<string, any>;
  }

  try {
    return JSON.parse(String(value)) as Record<string, any>;
  } catch {
    return null;
  }
}

async function googleAccessToken(): Promise<string | null> {
  const clientId = Deno.env
    .get("GOOGLE_CALENDAR_CLIENT_ID")
    ?.trim();

  const clientSecret = Deno.env
    .get("GOOGLE_CALENDAR_CLIENT_SECRET")
    ?.trim();

  const refreshToken = Deno.env
    .get("GOOGLE_CALENDAR_REFRESH_TOKEN")
    ?.trim();

  if (!clientId || !clientSecret || !refreshToken) {
    return null;
  }

  const res = await fetch(GOOGLE_TOKEN_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      refresh_token: refreshToken,
      grant_type: "refresh_token",
    }),
  });

  const json = await res.json();

  return String(json.access_token || "");
}

async function createGoogleMeetEvent(input: any) {
  const res = await fetch(
    `${CALENDAR_EVENTS_URL}?conferenceDataVersion=1`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${input.accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        summary: input.summary,
        description:
          "PhysioConnect online physiotherapy session",

        start: {
          dateTime: input.start.toISOString(),
          timeZone: "Asia/Kolkata",
        },

        end: {
          dateTime: input.end.toISOString(),
          timeZone: "Asia/Kolkata",
        },

        conferenceData: {
          createRequest: {
            requestId: input.requestId,
            conferenceSolutionKey: {
              type: "hangoutsMeet",
            },
          },
        },
      }),
    }
  );

  const json = await res.json();

  return (
    json.hangoutLink ||
    json.conferenceData?.entryPoints?.find(
      (e: any) => e.entryPointType === "video"
    )?.uri ||
    null
  );
}

function jsonResponse(
  data: unknown,
  status = 200
): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
