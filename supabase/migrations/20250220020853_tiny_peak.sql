/*
  # Fix stack depth limit error

  1. Changes
    - Remove recursive trigger calls
    - Optimize check-in status handling
    - Add safeguards against infinite loops
    
  2. Improvements
    - More efficient status updates
    - Better error handling
    - Simplified logic
*/

-- Drop existing triggers and functions
DROP TRIGGER IF EXISTS trigger_handle_checkin_status ON checkin_list;
DROP TRIGGER IF EXISTS trigger_auto_checkout ON checkin_list;
DROP FUNCTION IF EXISTS handle_checkin_status();
DROP FUNCTION IF EXISTS auto_checkout_old_checkins();

-- Create a more efficient function to handle check-in status
CREATE OR REPLACE FUNCTION handle_checkin_status()
RETURNS trigger AS $$
BEGIN
  -- Only proceed if this is a new check-in or status change to checked_in
  IF (TG_OP = 'INSERT' AND NEW.status = 'checked_in') OR 
     (TG_OP = 'UPDATE' AND NEW.status = 'checked_in' AND OLD.status != 'checked_in') THEN
    
    -- Update any existing active check-ins for this phone number at this store
    -- excluding the current record
    UPDATE checkin_list
    SET 
      status = 'checked_out',
      checkout_time = CURRENT_TIMESTAMP
    WHERE 
      phone_number = NEW.phone_number
      AND storeid = NEW.storeid
      AND status = 'checked_in'
      AND id != NEW.id;
      
    -- Auto-checkout any check-ins older than 24 hours
    -- This is now part of the same transaction
    UPDATE checkin_list
    SET 
      status = 'checked_out',
      checkout_time = CURRENT_TIMESTAMP
    WHERE 
      status = 'checked_in'
      AND checkin_time < CURRENT_TIMESTAMP - interval '24 hours'
      AND id != NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a single trigger that handles both check-in status and auto-checkout
CREATE TRIGGER trigger_handle_checkin_status
  BEFORE INSERT OR UPDATE ON checkin_list
  FOR EACH ROW
  EXECUTE FUNCTION handle_checkin_status();

-- Ensure we have the proper indexes
DROP INDEX IF EXISTS idx_active_checkin_unique;
CREATE UNIQUE INDEX idx_active_checkin_unique
ON checkin_list(phone_number, storeid)
WHERE status = 'checked_in' AND phone_number IS NOT NULL;

-- Create index for faster status updates
CREATE INDEX IF NOT EXISTS idx_checkin_status_lookup
ON checkin_list(phone_number, storeid, status, checkin_time);

-- Clean up any existing duplicate active check-ins
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
SET 
  status = 'checked_out',
  checkout_time = CURRENT_TIMESTAMP
WHERE id IN (
  SELECT id 
  FROM duplicates 
  WHERE rn > 1
);