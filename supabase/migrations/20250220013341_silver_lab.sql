/*
  # Fix checkin_list table constraints and indexes

  1. Changes
    - Add unique constraint for active check-ins
    - Add index for better query performance
    - Add trigger to auto-checkout old check-ins

  2. Security
    - Maintain existing RLS policies
*/

-- First, clean up any duplicate active check-ins
WITH duplicates AS (
  SELECT id,
         ROW_NUMBER() OVER (
           PARTITION BY phone_number, storeid
           ORDER BY checkin_time DESC
         ) as rn
  FROM checkin_list
  WHERE status = 'checked_in'
)
UPDATE checkin_list
SET status = 'checked_out',
    checkout_time = now()
WHERE id IN (
  SELECT id 
  FROM duplicates 
  WHERE rn > 1
);

-- Create a partial unique index for active check-ins
DROP INDEX IF EXISTS idx_active_checkin_unique;
CREATE UNIQUE INDEX idx_active_checkin_unique
ON checkin_list(phone_number, storeid)
WHERE status = 'checked_in';

-- Create a function to auto-checkout old check-ins
CREATE OR REPLACE FUNCTION auto_checkout_old_checkins()
RETURNS trigger AS $$
BEGIN
  -- Auto-checkout any check-ins older than 24 hours
  UPDATE checkin_list
  SET status = 'checked_out',
      checkout_time = now()
  WHERE status = 'checked_in'
  AND checkin_time < now() - interval '24 hours';
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to run the auto-checkout function
DROP TRIGGER IF EXISTS trigger_auto_checkout ON checkin_list;
CREATE TRIGGER trigger_auto_checkout
  BEFORE INSERT OR UPDATE ON checkin_list
  FOR EACH STATEMENT
  EXECUTE FUNCTION auto_checkout_old_checkins();