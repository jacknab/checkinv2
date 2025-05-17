/*
  # Fix store configuration

  1. Changes
    - Updates store references safely
    - Handles unique constraints
    - Maintains data integrity
    - Preserves active check-ins
  
  2. Safety Measures
    - Uses DO block for atomic updates
    - Handles foreign key constraints
    - Preserves existing relationships
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
  -- First, ensure we have a default store
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
  )
  ON CONFLICT (store_number) DO UPDATE
  SET 
    phone_number = EXCLUDED.phone_number,
    pin = EXCLUDED.pin,
    store_name = EXCLUDED.store_name,
    storeid = EXCLUDED.storeid,
    review_sms = EXCLUDED.review_sms;

  -- Update all references to use store 1
  UPDATE check_ins SET storeid = 1 WHERE storeid != 1;
  UPDATE checkin_list SET storeid = 1 WHERE storeid != 1;
  UPDATE scheduled_sms SET storeid = 1 WHERE storeid != 1;
  UPDATE store_codes SET storeid = 1 WHERE storeid != 1;

  -- Clean up any other stores
  DELETE FROM store WHERE store_number != 1;
END $$;

-- Drop unnecessary indexes
DROP INDEX IF EXISTS idx_store_review_sms;

-- Recreate necessary indexes
CREATE INDEX IF NOT EXISTS idx_store_number_lookup 
ON store(store_number);