/*
  # Fix store data fetch issues

  1. Changes
    - Add default store record if it doesn't exist
    - Ensure storeid matches store_number for consistency
    - Add index for faster lookups
*/

-- First ensure we have a default store
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
  '0000000000',
  '000000',
  'Default Store',
  9001,
  'Thank you for visiting! If you enjoyed your experience, please leave us a review: https://g.page/r/review'
)
ON CONFLICT (storeid) DO NOTHING;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_store_storeid 
ON store(storeid);

-- Add constraint to ensure storeid matches store_number
ALTER TABLE store
ADD CONSTRAINT check_storeid_matches_store_number
CHECK (storeid = store_number);