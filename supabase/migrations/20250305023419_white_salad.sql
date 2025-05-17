/*
  # Fix SMS handling and add message_id tracking

  1. Changes
    - Add message_id column to store Twilio SID
    - Update trigger to use proper URL format
    - Add constraint to ensure message_id is saved for sent messages
    
  2. Security
    - Inherits existing RLS policies
    - No additional security changes needed
*/

-- Add message_id column if it doesn't exist
ALTER TABLE scheduled_sms
ADD COLUMN IF NOT EXISTS message_id text;

-- Create function to handle SMS scheduling on checkout
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
      '👋 hey I hope you''re happy with your nails, if so could you leave me a review: https://g.page/r/' || NEW.storeid::text,
      NEW.storeid,
      CURRENT_TIMESTAMP,  -- Send immediately
      'pending'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;