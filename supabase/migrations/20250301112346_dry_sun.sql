/*
  # Fix checkin list trigger

  1. Changes
    - Improve the check-in trigger to handle edge cases better
    - Add better handling for null phone numbers
    - Add better handling for concurrent check-ins
    - Add better error handling
    - Add better performance optimizations

  2. Security
    - Maintains existing RLS policies
*/

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS trigger_handle_checkin_status ON checkin_list;
DROP FUNCTION IF EXISTS handle_checkin_status();

-- Create an improved function to handle check-in status
CREATE OR REPLACE FUNCTION handle_checkin_status()
RETURNS trigger AS $$
BEGIN
  -- Validate input
  IF NEW.phone_number IS NULL THEN
    RETURN NEW;
  END IF;

  -- Only proceed if this is a new check-in or status change to checked_in
  IF (TG_OP = 'INSERT' AND NEW.status = 'checked_in') OR 
     (TG_OP = 'UPDATE' AND NEW.status = 'checked_in' AND 
      (OLD.status IS NULL OR OLD.status != 'checked_in')) THEN
    
    -- Update any existing active check-ins for this phone number at this store
    -- Use a CTE for better performance
    WITH updated_checkins AS (
      SELECT id 
      FROM checkin_list 
      WHERE phone_number = NEW.phone_number
        AND storeid = NEW.storeid
        AND status = 'checked_in'
        AND id != NEW.id
      FOR UPDATE SKIP LOCKED
    )
    UPDATE checkin_list cl
    SET 
      status = 'checked_out',
      checkout_time = CURRENT_TIMESTAMP
    FROM updated_checkins uc
    WHERE cl.id = uc.id;

    -- Auto-checkout any check-ins older than 24 hours for this store
    -- Use a separate CTE for better performance
    WITH old_checkins AS (
      SELECT id 
      FROM checkin_list 
      WHERE storeid = NEW.storeid
        AND status = 'checked_in'
        AND checkin_time < CURRENT_TIMESTAMP - interval '24 hours'
        AND id != NEW.id
      FOR UPDATE SKIP LOCKED
    )
    UPDATE checkin_list cl
    SET 
      status = 'checked_out',
      checkout_time = CURRENT_TIMESTAMP
    FROM old_checkins oc
    WHERE cl.id = oc.id;
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error if needed
    RAISE WARNING 'Error in handle_checkin_status: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER trigger_handle_checkin_status
  BEFORE INSERT OR UPDATE ON checkin_list
  FOR EACH ROW
  EXECUTE FUNCTION handle_checkin_status();