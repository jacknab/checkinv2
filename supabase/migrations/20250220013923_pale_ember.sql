/*
  # Update checkout logic to delete records

  1. Changes
    - Add function to handle record deletion
    - Update trigger to handle deletion instead of status updates
    - Add indexes for better performance

  2. Security
    - Maintain existing RLS policies
*/

-- Create a function to handle record deletion
CREATE OR REPLACE FUNCTION handle_checkin_deletion()
RETURNS trigger AS $$
BEGIN
  -- If this is a deletion request
  IF (TG_OP = 'DELETE') THEN
    -- Log the deletion in a separate audit table if needed
    -- For now, just return OLD to allow the deletion
    RETURN OLD;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
DROP TRIGGER IF EXISTS trigger_handle_checkin_deletion ON checkin_list;
CREATE TRIGGER trigger_handle_checkin_deletion
  BEFORE DELETE ON checkin_list
  FOR EACH ROW
  EXECUTE FUNCTION handle_checkin_deletion();

-- Create index for faster deletions
CREATE INDEX IF NOT EXISTS idx_checkin_list_deletion
ON checkin_list (id, status, storeid);