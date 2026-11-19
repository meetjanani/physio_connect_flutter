-- Patient doctor catalog: public profile fields only (no payout / admin columns).
-- App queries `doctor` with an explicit column list. This view is for SQL/ops
-- and for any future API that should not leak Razorpay split fields.

CREATE OR REPLACE VIEW public.doctor_public AS
SELECT
  id,
  name,
  degree,
  experience,
  "drRegNumber",
  biodata,
  "profilePhotoUrl",
  "sessionTypeId",
  "timeSlotId",
  "userId"
FROM public.doctor
WHERE "isActive" = true;

GRANT SELECT ON public.doctor_public TO authenticated;

COMMENT ON VIEW public.doctor_public IS
  'Patient-safe doctor fields. Omits Razorpay, split, and admin columns.';

-- If RLS is already enabled on doctor, authenticated users can SELECT active rows.
-- Does not turn RLS on (that would break writes without a full policy set).
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'doctor'
      AND c.relrowsecurity
  ) THEN
    DROP POLICY IF EXISTS doctor_select_active_profiles ON public.doctor;
    CREATE POLICY doctor_select_active_profiles
      ON public.doctor
      FOR SELECT
      TO authenticated
      USING ("isActive" = true);
  END IF;
END $$;
