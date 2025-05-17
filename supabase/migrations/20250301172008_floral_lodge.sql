/*
  # Update checkin_list indexes and trigger

  1. Changes
    - Drop and recreate indexes for better performance
    - Update trigger function to handle check-ins more efficiently
    - Add constraints for data integrity

  2. Notes
    - Maintains existing storeid column
    - Improves query performance with better indexes
    - Enhances data consistency with trigger updates
*/

-- Drop existing indexes if they exist
DROP INDEX IF EXISTS idx_checkin_list_store_number;
DROP INDEX IF EXISTS idx_checkin_list_store_status;
DROP INDEX IF EXISTS idx_checkin_list_storeid;
DROP INDEX IF EXISTS idx_checkin_list_storeid_status;
DROP INDEX IF EXISTS idx_active_checkin_unique;

-- Create new optimized indexes
CREATE INDEX idx_checkin_list_storeid 
ON checkin_list(storeid);

CREATE INDEX idx_checkin_list_storeid_status 
ON checkin_list(storeid, status);

CREATE UNIQUE INDEX idx_active_checkin_unique
ON checkin_list(phone_number, storeid)
WHERE status = 'checked_in' AND phone_number IS NOT NULL;

-- Update the trigger function to use storeid
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
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Error in handle_checkin_status: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;