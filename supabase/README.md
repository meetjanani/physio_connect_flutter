# Publishing service coverage

Run the migration in `migrations/20260921182448_service_coverage.sql` against the Supabase project before releasing the mobile flow.

Also apply newer migrations in order:

- `migrations/20260925150000_booking_bulk_group.sql`
- `migrations/20260926140000_ratings_and_doctor_privacy.sql` (ratings columns + doctor.userId index)
- `migrations/20260930120000_doctor_privacy_indexes.sql` (booking/doctor indexes for multi-doctor filters)
- `migrations/20261003120000_doctor_public_catalog.sql` (`doctor_public` view + optional SELECT policy for active profiles)
- `migrations/20261004010000_online_session_meet.sql` (`session_type.mode`, `bookings.meetingUrl`)

## Online sessions (Google Meet)

Scheduling stays in the app (date + slot + pay). Video is a **Join** URL on the booking.

1. Set `session_type.mode` to `Online` (or keep `Home Visit`).
2. Deploy Edge Functions `verify-razorpay-payment` and `create-meet-for-booking`.
3. Optional auto-Meet: set function secrets
   - `GOOGLE_CALENDAR_CLIENT_ID`
   - `GOOGLE_CALENDAR_CLIENT_SECRET`
   - `GOOGLE_CALENDAR_REFRESH_TOKEN`
   for one PhysioConnect Google account with Calendar API enabled.
   Optional: `PHYSIOCONNECT_EMAIL` (defaults to `physioconnect.app@gmail.com`) is always added as a Meet attendee, along with the patient's and doctor's `users.guestEmail`.
4. If those secrets are missing, doctors can tap **Create Meet** / **Paste link** on the appointment.
5. WhatsApp is a backup chat (`wa.me`), not a scheduled video room.

## 5-doctor soft launch

Ops pack:

- [`ops/5_doctor_seed.sql`](ops/5_doctor_seed.sql) — seed template + verification queries
- [`ops/SMOKE_TEST.md`](ops/SMOKE_TEST.md) — go-live smoke matrix

Coverage model for this release: **one doctor per area** via `area.doctorId`.
Bookings store `doctor.userId` in `bookings.doctorId`.

## Lightweight admin / ops checklist

Until a dedicated admin app exists, manage coverage from the Supabase dashboard (Table Editor / SQL):

1. **Cities & areas** — `city_state`, `area`, `service_areas`
2. **Doctors** — `doctor` row with `userId` linked to `users.id`, `userType = 'Doctor'`, registration number, Razorpay Route account, `sessionTypeId` / `timeSlotId` CSVs
3. **Coverage link** — set `area.doctorId` (live path). Optionally also `doctor_service_areas`
4. **Pause coverage** — set `isActive = false` on `area` or `service_areas`
5. **Disputes / refunds** — patient cancel frees the slot only; refund via doctor long-press (48h), Razorpay dashboard, or support email/WhatsApp in Help tab

## Role model

App resolves doctor role from `users.userType` (`Doctor` / `Patient`), with a legacy ID allowlist fallback. Prefer setting `userType` correctly when onboarding doctors.

To publish a new home-visit area:

1. Add or activate the state, city, and area row.
2. Create one `service_areas` row for the area and set its center `latitude`, `longitude`, and `radiusKm` (for example `5`).
3. Set `area.doctorId` to the serving doctor's **table id**. Optionally add `doctor_service_areas`.
4. Add or activate `session_type` rows with `mode = 'Home Visit'`.
5. Configure the matching active `time_slot` rows. Set `serviceAreaId` when a slot is area-specific; leave it null for a shared slot.

For online sessions, publish `session_type` rows with `mode = 'Online'`; they do not require a `service_areas` row. Keep `isActive` false until the provider, pricing, and customer-facing copy are ready.

Existing bookings are intentionally retained. New bookings store JSON snapshots so historical details do not change when coverage is edited.

The app groups the published records as `State — City`, lets the patient select an area, and assigns the doctor from `area.doctorId`.
