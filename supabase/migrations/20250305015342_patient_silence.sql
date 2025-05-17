/*
  # Fix SMS constraints and add tracking fields

  1. Changes
    - Add phone number format validation
    - Add status tracking fields
    - Add performance indexes
    - Fix constraint conflicts
*/

-- First, ensure we have the proper columns
ALTER TABLE scheduled_sms
ADD COLUMN IF NOT EXISTS retry_count integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_error text,
ADD COLUMN IF NOT EXISTS last_attempt timestamptz;

-- Drop existing constraints if they exist
DO $$ 
BEGIN
  -- Drop phone number format constraint if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.check_constraints 
    WHERE constraint_name = 'check_phone_number_format'
  ) THEN
    ALTER TABLE scheduled_sms DROP CONSTRAINT check_phone_number_format;
  END IF;
END $$;

-- Add phone number format constraint
ALTER TABLE scheduled_sms
ADD CONSTRAINT check_phone_number_format
CHECK (phone_number ~ '^\+1[0-9]{10}$');

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_scheduled_sms_status_sendat 
ON scheduled_sms(status, sendat)
WHERE status = 'pending';

-- Create function to format phone numbers
CREATE OR REPLACE FUNCTION format_phone_number()
RETURNS trigger AS $$
BEGIN
  IF NEW.phone_number IS NOT NULL THEN
    -- Remove any non-numeric characters and ensure +1 prefix
    NEW.phone_number = CASE
      WHEN NEW.phone_number LIKE '+1%' THEN NEW.phone_number
      ELSE '+1' || regexp_replace(NEW.phone_number, '[^0-9]', '', 'g')
    END;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically format phone numbers
DROP TRIGGER IF EXISTS trigger_format_phone_number ON scheduled_sms;
CREATE TRIGGER trigger_format_phone_number
  BEFORE INSERT OR UPDATE ON scheduled_sms
  FOR EACH ROW
  EXECUTE FUNCTION format_phone_number();

-- Update existing records to ensure they have +1 prefix
UPDATE scheduled_sms
SET phone_number = CASE
  WHEN phone_number LIKE '+1%' THEN phone_number
  ELSE '+1' || regexp_replace(phone_number, '[^0-9]', '', 'g')
END
WHERE phone_number IS NOT NULL;