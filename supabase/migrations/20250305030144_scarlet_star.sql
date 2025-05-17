/*
  # Update SMS URL domain

  1. Changes
    - Change URL from tinyurl.com to fastcheckin.net in checkout SMS trigger
    - Keep existing SMS handling functionality
    
  2. Security
    - Inherits existing RLS policies
    - No additional security changes needed
*/

-- Create or replace function to handle SMS scheduling on checkout
CREATE OR REPLACE FUNCTION handle_checkout_sms()
RETURNS trigger AS $$
BEGIN
  -- Only proceed if status is changing to checked_out
  IF NEW.status = 'checked_out' AND 
     (OLD.status IS NULL OR OLD.status != 'checked_out') THEN
    
    -- Insert new scheduled SMS record with fastcheckin.net domain
    INSERT INTO scheduled_sms (
      phone_number,
      body,
      storeid,
      sendat,
      status
    )
    VALUES (
      NEW.phone_number,
      '👋 hey I hope you''re happy with your nails, if so could you leave me a review: ' || 
      'https://fastcheckin.net/' || NEW.storeid::text,
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