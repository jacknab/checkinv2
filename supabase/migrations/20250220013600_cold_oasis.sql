/*
  # Fix checkin list updates and constraints

  1. Changes
    - Add ON CONFLICT handling for phone_number and storeid
    - Add trigger to handle checkin status updates
    - Add index for faster lookups
    - Add constraint to ensure only one active check-in per phone number per store

  2. Security
    - Maintain existing RLS policies
*/

-- First, ensure we have the proper unique constraint
ALTER TABLE checkin_list
DROP CONSTRAINT IF EXISTS unique_active_checkin;

-- Create a partial unique constraint for active check-ins
CREATE UNIQUE INDEX IF NOT EXISTS unique_active_checkin
ON checkin_list (phone_number, storeid)
WHERE status = 'checked_in' AND phone_number IS NOT NULL;

-- Create a function to handle check-in status
CREATE OR REPLACE FUNCTION handle_checkin_status()
RETURNS trigger AS $$
BEGIN
  -- If this is a new check-in or status update to checked_in
  IF (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NEW.status = 'checked_in')) THEN
    -- Update any existing active check-ins for this phone number at this store
    UPDATE checkin_list
    SET status = 'checked_out',
        checkout_time = now()
    WHERE phone_number = NEW.phone_number
      AND storeid = NEW.storeid
      AND status = 'checked_in'
      AND id != NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
DROP TRIGGER IF EXISTS trigger_handle_checkin_status ON checkin_list;
CREATE TRIGGER trigger_handle_checkin_status
  BEFORE INSERT OR UPDATE ON checkin_list
  FOR EACH ROW
  EXECUTE FUNCTION handle_checkin_status();

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_checkin_list_lookup
ON checkin_list (storeid, status, checkin_time DESC);

-- Add NOT NULL constraints where appropriate
ALTER TABLE checkin_list
  ALTER COLUMN storeid SET NOT NULL,
  ALTER COLUMN status SET NOT NULL,
  ALTER COLUMN first_name SET NOT NULL;