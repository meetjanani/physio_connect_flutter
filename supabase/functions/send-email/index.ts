const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token";
const GMAIL_SEND_URL =
  "https://gmail.googleapis.com/gmail/v1/users/me/messages/send";
const MAX_PDF_CHARS = 4_000_000;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (req.method !== "POST") {
      return jsonResponse({ error: "Method not allowed" }, 405);
    }

    const body = await req.json();
    const toEmail = String(body.toEmail ?? "").trim();
    const patientName = String(body.patientName ?? "Patient").trim();
    const status = String(body.status ?? "").trim();
    const appointmentDate = String(body.appointmentDate ?? "").trim();
    const pdfBase64 = typeof body.pdfBase64 === "string"
      ? body.pdfBase64.replace(/\s/g, "")
      : "";
    const invoiceName = String(body.invoiceName ?? "invoice.pdf").trim() ||
      "invoice.pdf";

    if (!toEmail || !toEmail.includes("@")) {
      return jsonResponse({ error: "toEmail is required" }, 400);
    }
    if (!status) {
      return jsonResponse({ error: "status is required" }, 400);
    }
    if (pdfBase64.length > MAX_PDF_CHARS) {
      return jsonResponse(
        { error: "PDF attachment is too large for this function" },
        413,
      );
    }

    const accessToken = await googleAccessToken();
    if (!accessToken) {
      return jsonResponse(
        {
          error:
            "Google credentials missing or token refresh failed. Check GOOGLE_CALENDAR_* secrets and that the refresh token includes gmail.send.",
        },
        500,
      );
    }

    const raw = buildRawMessage({
      toEmail,
      patientName,
      status,
      appointmentDate,
      pdfBase64,
      invoiceName,
    });

    const gmailRes = await fetch(GMAIL_SEND_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ raw }),
      signal: AbortSignal.timeout(15000),
    });

    const gmailJson = await gmailRes.json();
    if (!gmailRes.ok) {
      return jsonResponse(
        {
          error: "Gmail could not send the email",
          gmail: gmailJson,
        },
        gmailRes.status >= 400 && gmailRes.status < 600 ? gmailRes.status : 502,
      );
    }

    return jsonResponse({
      success: true,
      messageId: gmailJson.id ?? null,
    });
  } catch (_error) {
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function googleAccessToken() {
  const clientId = Deno.env.get("GOOGLE_CALENDAR_CLIENT_ID")?.trim();
  const clientSecret = Deno.env.get("GOOGLE_CALENDAR_CLIENT_SECRET")?.trim();
  const refreshToken = Deno.env.get("GOOGLE_CALENDAR_REFRESH_TOKEN")?.trim();

  if (!clientId || !clientSecret || !refreshToken) {
    return null;
  }

  const res = await fetch(GOOGLE_TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      refresh_token: refreshToken,
      grant_type: "refresh_token",
    }),
    signal: AbortSignal.timeout(10000),
  });

  const json = await res.json();
  const token = String(json.access_token ?? "").trim();
  if (!res.ok || !token) {
    return null;
  }
  return token;
}

function generateEmailHtml(
  patientName: string,
  status: string,
  date: string,
) {
  const playStoreLink =
    "https://play.google.com/store/apps/details?id=com.physio.connect.physio_connect";
  const lowered = status.toLowerCase();
  const isCancelledOrRefunded =
    lowered === "cancelled" || lowered === "refunded";
  const statusColor = isCancelledOrRefunded ? "#d93025" : "#188038";

  let bodyMessage = "";
  if (lowered === "completed") {
    bodyMessage =
      `We hope you had a great physiotherapy session on <strong>${escapeHtml(date)}</strong>. Your appointment has been marked as <strong>${escapeHtml(status)}</strong>.`;
  } else if (isCancelledOrRefunded) {
    bodyMessage =
      `Your physiotherapy session scheduled for <strong>${escapeHtml(date)}</strong> has been <strong>${escapeHtml(status)}</strong>. If a refund is applicable, it will be processed according to our platform policies.`;
  } else {
    bodyMessage =
      `Your physiotherapy session on <strong>${escapeHtml(date)}</strong> has been marked as <strong>${escapeHtml(status)}</strong>.`;
  }

  return `<!DOCTYPE html>
<html>
  <body style="font-family: Arial, sans-serif; color: #202124; line-height: 1.5;">
    <p>Hello ${escapeHtml(patientName)},</p>
    <p>${bodyMessage}</p>
    <p style="color:${statusColor}; font-weight: bold;">Status: ${escapeHtml(status)}</p>
    <p>Open the PhysioConnect app for details, or get it on
      <a href="${playStoreLink}">Google Play</a>.
    </p>
    <p>PhysioConnect</p>
  </body>
</html>`;
}

function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function encodeSubject(subject: string) {
  const bytes = new TextEncoder().encode(subject);
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return `=?UTF-8?B?${btoa(binary)}?=`;
}

function toBase64Url(rawMime: string) {
  const bytes = new TextEncoder().encode(rawMime);
  let binary = "";
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    binary += String.fromCharCode(...bytes.subarray(i, i + chunk));
  }
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll(
    "=",
    "",
  );
}

function foldBase64(value: string) {
  const lines: string[] = [];
  for (let i = 0; i < value.length; i += 76) {
    lines.push(value.slice(i, i + 76));
  }
  return lines.join("\r\n");
}

function buildRawMessage(input: {
  toEmail: string;
  patientName: string;
  status: string;
  appointmentDate: string;
  pdfBase64: string;
  invoiceName: string;
}) {
  const subject = `PhysioConnect appointment ${input.status}`;
  const html = generateEmailHtml(
    input.patientName,
    input.status,
    input.appointmentDate,
  );
  const safeName = input.invoiceName.replaceAll(/[\r\n"]/g, "_");
  const hasPdf = input.pdfBase64.length > 0;
  const boundary = `pc_${crypto.randomUUID().replaceAll("-", "")}`;

  const headers = [
    `To: ${input.toEmail}`,
    "From: me",
    `Subject: ${encodeSubject(subject)}`,
    "MIME-Version: 1.0",
  ];

  let mime: string;
  if (hasPdf) {
    mime = [
      ...headers,
      `Content-Type: multipart/mixed; boundary="${boundary}"`,
      "",
      `--${boundary}`,
      "Content-Type: text/html; charset=UTF-8",
      "Content-Transfer-Encoding: 7bit",
      "",
      html,
      `--${boundary}`,
      "Content-Type: application/pdf",
      "Content-Transfer-Encoding: base64",
      `Content-Disposition: attachment; filename="${safeName}"`,
      "",
      foldBase64(input.pdfBase64),
      `--${boundary}--`,
      "",
    ].join("\r\n");
  } else {
    mime = [
      ...headers,
      "Content-Type: text/html; charset=UTF-8",
      "",
      html,
    ].join("\r\n");
  }

  return toBase64Url(mime);
}
