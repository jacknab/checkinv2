/*
  # Update check-in trigger function

  1. Changes
    - Simplify trigger function to only handle active check-ins
    - Remove auto-checkout of old check-ins to improve performance
    - Use store_number consistently

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
  -- Only proceed if this is a new check-in or status change to checked_in
  IF (TG_OP = 'INSERT' AND NEW.status = 'checked_in') OR 
     (TG_OP = 'UPDATE' AND NEW.status = 'checked_in' AND 
      (OLD.status IS NULL OR OLD.status != 'checked_in')) THEN
    
    -- Update any existing active check-ins for this phone number at this store
    UPDATE checkin_list
    SET 
      status = 'checked_out',
      checkout_time = CURRENT_TIMESTAMP
    WHERE 
      phone_number = NEW.phone_number
      AND store_number = NEW.store_number
      AND status = 'checked_in'
      AND id != NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER trigger_handle_checkin_status
  BEFORE INSERT OR UPDATE ON checkin_list
  FOR EACH ROW
  EXECUTE FUNCTION handle_checkin_status();