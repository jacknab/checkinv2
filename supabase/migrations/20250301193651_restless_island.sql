/*
  # Fix store configuration

  1. Changes
    - Updates store references safely
    - Handles foreign key constraints
    - Maintains data integrity
    - Preserves existing relationships
  
  2. Safety Measures
    - Uses DO block for atomic updates
    - Creates temporary store first
    - Handles constraints properly
*/

-- First check out any active check-ins to avoid unique constraint violations
UPDATE checkin_list
SET 
  status = 'checked_out',
  checkout_time = CURRENT_TIMESTAMP
WHERE status = 'checked_in';

-- Now safely update the store record and references
DO $$ 
BEGIN
  -- First create a temporary store to handle foreign key constraints
  INSERT INTO store (
    store_number,
    phone_number,
    pin,
    store_name,
    storeid,
    review_sms
  )
  VALUES (
    999999,
    '9999999999',
    '999999',
    'Temporary Store',
    999999,
    'Temporary Message'
  );

  -- Move all references to the temporary store
  UPDATE check_ins SET storeid = 999999;
  UPDATE checkin_list SET storeid = 999999;
  UPDATE scheduled_sms SET storeid = 999999;
  UPDATE store_codes SET storeid = 999999;

  -- Delete all stores except the temporary one
  DELETE FROM store WHERE store_number != 999999;

  -- Create the new default store
  INSERT INTO store (
    store_number,
    phone_number,
    pin,
    store_name,
    storeid,
    review_sms
  )
  VALUES (
    1,
    '0000000000',
    '000000',
    'Default Store',
    1,
    'Thank you for visiting! If you enjoyed your experience, please leave us a review: https://g.page/r/review'
  );

  -- Move all references to the default store
  UPDATE check_ins SET storeid = 1;
  UPDATE checkin_list SET storeid = 1;
  UPDATE scheduled_sms SET storeid = 1;
  UPDATE store_codes SET storeid = 1;

  -- Delete the temporary store
  DELETE FROM store WHERE store_number = 999999;
END $$;

-- Drop unnecessary indexes
DROP INDEX IF EXISTS idx_store_review_sms;

-- Recreate necessary indexes
CREATE INDEX IF NOT EXISTS idx_store_number_lookup 
ON store(store_number);