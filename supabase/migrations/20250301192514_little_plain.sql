/*
  # Revert recent changes

  1. Changes
    - Drop store_sms_messages table
    - Safely handle store table updates
    - Clean up indexes
    
  2. Security
    - Maintain existing RLS policies
    - Keep existing constraints
*/

-- Drop store_sms_messages table if it exists
DROP TABLE IF EXISTS store_sms_messages;

-- First check if store 9001 exists
DO $$ 
BEGIN
  -- If store 9001 doesn't exist, we can safely update store 1
  IF NOT EXISTS (
    SELECT 1 FROM store WHERE store_number = 9001
  ) THEN
    UPDATE store
    SET 
      store_number = 9001,
      phone_number = '0000000000',
      pin = '000000',
      store_name = 'Default Store',
      storeid = 9001,
      review_sms = 'Thank you for visiting! If you enjoyed your experience, please leave us a review: https://g.page/r/review'
    WHERE store_number = 1;
  ELSE
    -- If store 9001 exists, update its values without changing the store_number
    UPDATE store
    SET 
      phone_number = '0000000000',
      pin = '000000',
      store_name = 'Default Store',
      review_sms = 'Thank you for visiting! If you enjoyed your experience, please leave us a review: https://g.page/r/review'
    WHERE store_number = 9001;
  END IF;
END $$;

-- Drop unnecessary indexes
DROP INDEX IF EXISTS idx_store_review_sms;

-- Recreate necessary indexes
CREATE INDEX IF NOT EXISTS idx_store_number_lookup 
ON store(store_number);