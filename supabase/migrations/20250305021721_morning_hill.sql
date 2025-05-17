/*
  # Add SMS scheduling trigger on checkout

  1. Changes
    - Creates a trigger function to handle SMS scheduling on checkout
    - Creates a trigger that fires when checkin_list status changes to 'checked_out'
    - Automatically creates scheduled_sms record with review request message
    
  2. Security
    - Inherits existing RLS policies
    - No additional security changes needed
*/

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
      '👋 hey I hope your happy with your nails, if so could you leave me a review: https://tinyurl.com/' || NEW.storeid::text,
      NEW.storeid,
      CURRENT_TIMESTAMP,  -- Send immediately
      'pending'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_checkout_sms ON checkin_list;
CREATE TRIGGER trigger_checkout_sms
  AFTER UPDATE OF status ON checkin_list
  FOR EACH ROW
  EXECUTE FUNCTION handle_checkout_sms();