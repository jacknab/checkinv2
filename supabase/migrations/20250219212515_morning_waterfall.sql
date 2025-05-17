/*
  # Auth Settings Configuration Note

  The OTP expiry time cannot be set through SQL migrations. Instead, this needs to be configured through the Supabase Dashboard:

  1. Go to Authentication > Providers
  2. Under Email Provider settings
  3. Set "Email OTP Expiry" to 30 minutes (1800 seconds)

  This ensures:
  - Better security with shorter OTP validity
  - Compliance with security best practices
  - Protection against potential replay attacks
*/

-- This migration file serves as documentation only
-- No SQL changes are needed as auth settings are managed through the dashboard