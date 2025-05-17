/*
  # Fix store configuration and constraints

  1. Create default store
    - Ensures a consistent default store with ID 9001
    - Sets up review SMS message
  2. Security
    - Maintains RLS policies
  3. Indexes
    - Creates optimized indexes for better performance
*/

-- Create a transaction for atomicity
BEGIN;

-- First, ensure any active check-ins are checked out
UPDATE checkin_list
SET 
  status = 'checked_out',
  checkout_time = CURRENT_TIMESTAMP
WHERE status = 'checked_in';

-- Next, make sure we have the default store with ID 9001
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
  '9991112222',
  '000000',
  'Default Store',
  9001,
  'Thank you for visiting! If you enjoyed your experience, please leave us a review: https://g.page/r/review'
)
ON CONFLICT (store_number) DO UPDATE
SET 
  phone_number = EXCLUDED.phone_number,
  pin = EXCLUDED.pin,
  store_name = EXCLUDED.store_name,
  storeid = EXCLUDED.storeid,
  review_sms = EXCLUDED.review_sms;

-- Update all references to store 9001
UPDATE check_ins SET storeid = 9001 WHERE storeid != 9001;
UPDATE checkin_list SET storeid = 9001 WHERE storeid != 9001;
UPDATE scheduled_sms SET storeid = 9001 WHERE storeid != 9001;
UPDATE store_codes SET storeid = 9001 WHERE storeid != 9001;

-- Remove any other stores that might have been created
DELETE FROM store WHERE store_number != 9001;

-- Rebuild indexes for better performance
DROP INDEX IF EXISTS idx_store_review_sms;
DROP INDEX IF EXISTS idx_store_storeid;
DROP INDEX IF EXISTS idx_active_checkin_unique;

-- Create optimized indexes
CREATE INDEX IF NOT EXISTS idx_store_number_lookup 
ON store(store_number);

CREATE INDEX IF NOT EXISTS idx_check_ins_storeid
ON check_ins(storeid);

CREATE INDEX IF NOT EXISTS idx_checkin_list_storeid
ON checkin_list(storeid);

CREATE INDEX IF NOT EXISTS idx_checkin_list_phone_number
ON checkin_list(phone_number);

CREATE UNIQUE INDEX IF NOT EXISTS idx_active_checkin_unique
ON checkin_list(phone_number, storeid)
WHERE status = 'checked_in' AND phone_number IS NOT NULL;

-- Add constraints to ensure data integrity
ALTER TABLE store
DROP CONSTRAINT IF EXISTS check_review_sms_not_empty;

ALTER TABLE store
ADD CONSTRAINT check_review_sms_not_empty 
CHECK (review_sms <> '');

COMMIT;