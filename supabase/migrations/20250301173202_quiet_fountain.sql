/*
  # Add phone number prefix to scheduled_sms table

  1. Changes
    - Add check constraint to ensure phone numbers start with +1
    - Update existing records to add +1 prefix if missing
    - Add trigger to automatically format phone numbers
*/

-- First, update existing records to ensure they have +1 prefix
UPDATE scheduled_sms
SET phone_number = CASE
  WHEN phone_number LIKE '+1%' THEN phone_number
  ELSE '+1' || regexp_replace(phone_number, '[^0-9]', '', 'g')
END
WHERE phone_number IS NOT NULL;

-- Add check constraint to ensure phone numbers start with +1
ALTER TABLE scheduled_sms
ADD CONSTRAINT check_phone_number_format
CHECK (phone_number LIKE '+1%');

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
CREATE TRIGGER trigger_format_phone_number
  BEFORE INSERT OR UPDATE ON scheduled_sms
  FOR EACH ROW
  EXECUTE FUNCTION format_phone_number();

-- Create index for phone number lookups
CREATE INDEX IF NOT EXISTS idx_scheduled_sms_phone_number
ON scheduled_sms(phone_number);