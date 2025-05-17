/*
  # Delete Store Record for Store 1

  1. Changes
    - Deletes the store record for store number 1
    - Keeps store 9001 configuration intact
    - Updates any references to store 1 to point to store 9001
    - Ensures proper cleanup

  2. Tables Updated
    - store
    - check_ins
    - checkin_list
    - scheduled_sms
    - store_codes
*/

-- Create a transaction for atomicity
BEGIN;

-- First update any references from store 1 to store 9001
UPDATE check_ins SET storeid = 9001 WHERE storeid = 1;
UPDATE checkin_list SET storeid = 9001 WHERE storeid = 1;
UPDATE scheduled_sms SET storeid = 9001 WHERE storeid = 1;
UPDATE store_codes SET storeid = 9001 WHERE storeid = 1;

-- Now we can safely delete store 1
DELETE FROM store 
WHERE store_number = 1;

-- Create index for better query performance if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_store_number_lookup 
ON store(store_number);

COMMIT;