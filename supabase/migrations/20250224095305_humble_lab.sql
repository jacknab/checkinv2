/*
  # Fix Duplicate Check-ins

  1. Changes
    - Remove unique constraint on phone_number
    - Add composite unique constraint for active check-ins
    - Update triggers to handle check-in status properly
    
  2. Security
    - Maintain existing RLS policies
*/

-- First, remove the problematic unique constraint if it exists
ALTER TABLE checkin_list 
DROP CONSTRAINT IF EXISTS checkin_list_phone_number_key;

-- Drop existing indexes that might conflict
DROP INDEX IF EXISTS idx_active_checkin_unique;
DROP INDEX IF EXISTS idx_checkin_list_phone_number;

-- Create a new partial unique index for active check-ins
CREATE UNIQUE INDEX idx_active_checkin_unique
ON checkin_list(phone_number, storeid)
WHERE status = 'checked_in' AND phone_number IS NOT NULL;

-- Create a regular index for phone number lookups
CREATE INDEX idx_checkin_list_phone_number
ON checkin_list(phone_number);

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
      AND storeid = NEW.storeid
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