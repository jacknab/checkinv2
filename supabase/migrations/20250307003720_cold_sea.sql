/*
  # Add SMS Count Update Trigger

  1. New Function
    - Creates a trigger function to update store SMS counts
    - Automatically updates store.sms_count when SMS status changes to 'sent'
    - Maintains accurate count of sent messages per store

  2. Trigger
    - Creates a trigger that fires after updates to scheduled_sms table
    - Only updates count when status changes to 'sent'
    - Ensures atomic updates to maintain count accuracy
*/

-- Create function to update SMS count
CREATE OR REPLACE FUNCTION update_store_sms_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Only update count when status changes to 'sent'
  IF NEW.status = 'sent' AND (OLD.status IS NULL OR OLD.status != 'sent') THEN
    UPDATE store
    SET sms_count = COALESCE(sms_count, 0) + 1
    WHERE store_number = NEW.storeid;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger on scheduled_sms table
CREATE TRIGGER trigger_update_sms_count
  AFTER UPDATE OF status
  ON scheduled_sms
  FOR EACH ROW
  EXECUTE FUNCTION update_store_sms_count();