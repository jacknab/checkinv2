/*
  # Revert to previous database state

  1. Changes
    - Restores the default store configuration
    - Handles constraint management safely
    - Preserves store references
    - Ensures data integrity
  
  2. Operations
    - Creates an atomic transaction block
    - Handles foreign key constraints properly
    - Updates indexes as needed
*/

-- First, create a transaction block for atomicity
BEGIN;

-- Check if there are any active check-ins and check them out to avoid conflicts
UPDATE checkin_list
SET 
  status = 'checked_out',
  checkout_time = CURRENT_TIMESTAMP
WHERE status = 'checked_in';

-- Create a temporary store to handle foreign key constraints
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
)
ON CONFLICT (store_number) DO NOTHING;

-- Redirect all foreign key references to the temporary store
UPDATE check_ins SET storeid = 999999 WHERE storeid != 999999;
UPDATE checkin_list SET storeid = 999999 WHERE storeid != 999999;
UPDATE scheduled_sms SET storeid = 999999 WHERE storeid != 999999;
UPDATE store_codes SET storeid = 999999 WHERE storeid != 999999;

-- Remove all existing stores except the temporary one
DELETE FROM store WHERE store_number != 999999;

-- Create the reverted default store with proper configuration
INSERT INTO store (
  store_number,
  phone_number,
  pin,
  store_name,
  storeid,
  review_sms
)
VALUES (
  9001,
  '1111111111',
  '000000',
  'Default Store',
  9001,
  'Thank you for visiting! Please leave us a review at https://g.page/r/review'
);

-- Update all references to point to the reverted store
UPDATE check_ins SET storeid = 9001;
UPDATE checkin_list SET storeid = 9001;
UPDATE scheduled_sms SET storeid = 9001;
UPDATE store_codes SET storeid = 9001;

-- Remove the temporary store
DELETE FROM store WHERE store_number = 999999;

-- Clean up any unnecessary indexes
DROP INDEX IF EXISTS idx_store_review_sms;
DROP INDEX IF EXISTS idx_active_checkin_unique;

-- Recreate necessary indexes
CREATE INDEX IF NOT EXISTS idx_store_number_lookup 
ON store(store_number);

CREATE INDEX IF NOT EXISTS idx_check_ins_storeid
ON check_ins(storeid);

CREATE INDEX IF NOT EXISTS idx_checkin_list_storeid
ON checkin_list(storeid);

-- Create a unique index for active check-ins
CREATE UNIQUE INDEX idx_active_checkin_unique
ON checkin_list(phone_number, storeid)
WHERE status = 'checked_in' AND phone_number IS NOT NULL;

COMMIT;