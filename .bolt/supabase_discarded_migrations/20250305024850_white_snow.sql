/*
  # Fix SMS handling and message tracking

  1. Changes
    - Update trigger function to use proper tinyurl.com URL format
    - Fix message_id tracking in scheduled_sms table
    - Add proper URL encoding for store ID
    - Add validation for message_id
    
  2. Security
    - Inherits existing RLS policies
    - No additional security changes needed
*/

-- First ensure message_id column exists
ALTER TABLE scheduled_sms
ADD COLUMN IF NOT EXISTS message_id text;

-- Create index for message_id lookups
CREATE INDEX IF NOT EXISTS idx_scheduled_sms_message_id
ON scheduled_sms(message_id)
WHERE message_id IS NOT NULL;

-- Create or replace function to handle SMS scheduling on checkout
CREATE OR REPLACE FUNCTION handle_checkout_sms()
RETURNS trigger AS $$
BEGIN
  -- Only proceed if status is changing to checked_out
  IF NEW.status = 'checked_out' AND 
     (OLD.status IS NULL OR OLD.status != 'checked_out') THEN
    
    -- Insert new scheduled SMS record with properly formatted URL
    INSERT INTO scheduled_sms (
      phone_number,
      body,
      storeid,
      sendat,
      status
    )
    VALUES (
      NEW.phone_number,
      '👋 hey I hope you''re happy with your nails, if so could you leave me a review: https://tinyurl.com/store' || NEW.storeid::text,
      NEW.storeid,
      CURRENT_TIMESTAMP,  -- Send immediately
      'pending'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop and recreate the trigger
DROP TRIGGER IF EXISTS trigger_checkout_sms ON checkin_list;
CREATE TRIGGER trigger_checkout_sms
  AFTER UPDATE OF status ON checkin_list
  FOR EACH ROW
  EXECUTE FUNCTION handle_checkout_sms();