-- Online sessions: session_type.mode + booking Meet URL (no payout changes).

ALTER TABLE public.session_type
  ADD COLUMN IF NOT EXISTS mode text NOT NULL DEFAULT 'Home Visit';

COMMENT ON COLUMN public.session_type.mode IS
  'Home Visit or Online. Online bookings skip visit address.';

ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS "meetingUrl" text;

ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS "meetingProvider" text;

COMMENT ON COLUMN public.bookings."meetingUrl" IS
  'Google Meet (or pasted) join URL for online sessions.';

COMMENT ON COLUMN public.bookings."meetingProvider" IS
  'google_meet, pasted, or empty for home visits.';

ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS "guestEmail" text;

COMMENT ON COLUMN public.bookings."guestEmail" IS
  'Optional patient email for Google Calendar / Meet invites on online sessions.';
