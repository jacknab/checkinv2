/*
  # Add SMS count update trigger

  1. Changes
    - Create trigger function to update store SMS count
    - Add trigger on scheduled_sms table for status updates

  2. Details
    - Trigger fires when scheduled_sms status is updated to 'sent'
    - Updates store.sms_count for the corresponding store
    - Ensures accurate SMS count tracking
*/

-- Create or replace the trigger function
CREATE OR REPLACE FUNCTION update_store_sms_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Only proceed if status is being changed to 'sent'
  IF (TG_OP = 'UPDATE' AND NEW.status = 'sent' AND (OLD.status IS NULL OR OLD.status != 'sent')) THEN
    -- Update the store's SMS count
    UPDATE store
    SET sms_count = COALESCE(sms_count, 0) + 1
    WHERE store_number = NEW.storeid;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger on scheduled_sms table
DROP TRIGGER IF EXISTS trigger_update_sms_count ON scheduled_sms;
CREATE TRIGGER trigger_update_sms_count
  AFTER UPDATE OF status
  ON scheduled_sms
  FOR EACH ROW
  EXECUTE FUNCTION update_store_sms_count();