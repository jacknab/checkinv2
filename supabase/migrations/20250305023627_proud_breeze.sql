/*
  # Update SMS URL format

  1. Changes
    - Update trigger function to use tinyurl.com URL format
    - Fix typo in message text ("your" to "you're")
    
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
    
    -- Insert new scheduled SMS record
    INSERT INTO scheduled_sms (
      phone_number,
      body,
      storeid,
      sendat,
      status
    )
    VALUES (
      NEW.phone_number,
      '👋 hey I hope you''re happy with your nails, if so could you leave me a review: https://tinyurl.com/' || NEW.storeid::text,
      NEW.storeid,
      CURRENT_TIMESTAMP,  -- Send immediately
      'pending'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;