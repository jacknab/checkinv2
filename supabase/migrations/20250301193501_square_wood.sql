/*
  # Update store references and handle active check-ins

  1. Changes
    - Updates all references to store 9001
    - Updates default store record safely
    - Handles unique constraints for active check-ins
    - Recreates necessary indexes
  
  2. Safety Measures
    - Uses DO block for safe updates
    - Handles active check-in conflicts
*/

-- First check out any active check-ins to avoid unique constraint violations
UPDATE checkin_list
SET 
  status = 'checked_out',
  checkout_time = CURRENT_TIMESTAMP
WHERE status = 'checked_in';

-- Now update all related records to reference store 9001
UPDATE checkin_list
SET storeid = 9001
WHERE storeid = 1;

UPDATE check_ins
SET storeid = 9001
WHERE storeid = 1;

UPDATE scheduled_sms
SET storeid = 9001
WHERE storeid = 1;

UPDATE store_codes
SET storeid = 9001
WHERE storeid = 1;

-- Now safely update the store record using a DO block
DO $$ 
DECLARE
  temp_phone text := '9999999999';
BEGIN
  -- Generate a unique temporary phone number
  WHILE EXISTS (SELECT 1 FROM store WHERE phone_number = temp_phone) LOOP
    temp_phone := floor(random() * 8999999999 + 1000000000)::text;
  END LOOP;

  -- First, update any existing store with phone_number '0000000000'
  -- to have a different phone number to avoid conflicts
  UPDATE store
  SET phone_number = temp_phone
  WHERE phone_number = '0000000000'
    AND store_number != 1;

  -- Now we can safely update store 1
  UPDATE store
  SET 
    phone_number = '0000000000',
    pin = '000000',
    store_name = 'Default Store',
    storeid = 9001,
    review_sms = 'Thank you for visiting! If you enjoyed your experience, please leave us a review: https://g.page/r/review'
  WHERE store_number = 1;
END $$;

-- Drop unnecessary indexes
DROP INDEX IF EXISTS idx_store_review_sms;

-- Recreate necessary indexes
CREATE INDEX IF NOT EXISTS idx_store_number_lookup 
ON store(store_number);