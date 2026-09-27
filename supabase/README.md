# Publishing service coverage

Run the migration in `migrations/20260921182448_service_coverage.sql` against the Supabase project before releasing the mobile flow.

Also apply newer migrations in order:

- `migrations/20260925150000_booking_bulk_group.sql`
- `migrations/20260926140000_ratings_and_doctor_privacy.sql` (ratings columns + doctor.userId index)

## Lightweight admin / ops checklist

Until a dedicated admin app exists, manage coverage from the Supabase dashboard (Table Editor / SQL):

1. **Cities & areas** — `city_state`, `area`, `service_areas`
2. **Doctors** — `doctor` row with `userId` linked to `users.id`, `userType = 'Doctor'`, registration number, Razorpay Route account, `sessionTypeId` / `timeSlotId` CSVs
3. **Coverage link** — `doctor_service_areas` for each area a doctor serves
4. **Pause coverage** — set `isActive = false` on `service_areas` or `doctor_service_areas`
5. **Disputes / refunds** — use booking detail refund (doctor, 48h) or Razorpay dashboard; support email in app Help tab

## Role model

App resolves doctor role from `users.userType` (`Doctor` / `Patient`), with a legacy ID allowlist fallback. Prefer setting `userType` correctly when onboarding doctors.

To publish a new home-visit area:

1. Add or activate the state, city, and area row.
2. Create one `service_areas` row for the area and set its center `latitude`, `longitude`, and `radiusKm` (for example `5`).
3. Add an active `doctor_service_areas` row for every doctor who serves it, and set each doctor's `latitude` and `longitude`.
4. Add or activate `session_type` rows with `mode = 'Home Visit'`.
5. Configure the matching active `time_slot` rows. Set `serviceAreaId` when a slot is area-specific; leave it null for a shared slot.

For online sessions, publish `session_type` rows with `mode = 'Online'`; they do not require a `service_areas` row. Keep `isActive` false until the provider, pricing, and customer-facing copy are ready.

Existing bookings are intentionally retained. New bookings store `serviceAreaId`, `areaId`, and `serviceMode` in addition to the existing JSON snapshots so historical details do not change when coverage is edited.

The app groups the published records as `State — City`, lets the patient select an area, and can use GPS to find the nearest service-area center within that area's radius. The assigned doctor is then selected by distance from the patient's coordinates; if coordinates are unavailable, the first eligible doctor is used.
