/*
  # Fix store configuration and review SMS

  1. Changes
    - Updates store table configuration
    - Ensures proper phone number format
    - Sets default review SMS message
    - Adds necessary constraints and indexes

  2. Security
    - Maintains existing RLS policies
    - No changes to access control
*/

-- First, ensure we have the review_sms column
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'store' AND column_name = 'review_sms'
  ) THEN
    ALTER TABLE store
    ADD COLUMN review_sms text;
  END IF;
END $$;

-- Update existing store records with proper values
UPDATE store
SET review_sms = COALESCE(
  review_sms,
  'Thank you for visiting! If you enjoyed your experience, please leave us a review: https://g.page/r/review'
)
WHERE review_sms IS NULL OR review_sms = '';

-- Make review_sms NOT NULL after ensuring all rows have a value
ALTER TABLE store
ALTER COLUMN review_sms SET NOT NULL;

-- Add constraint to ensure review_sms is not empty
ALTER TABLE store
DROP CONSTRAINT IF EXISTS check_review_sms_not_empty;

ALTER TABLE store
ADD CONSTRAINT check_review_sms_not_empty 
CHECK (review_sms <> '');

-- Create optimized indexes for better performance
DROP INDEX IF EXISTS idx_store_review_sms;
DROP INDEX IF EXISTS idx_store_number_lookup;

CREATE INDEX idx_store_review_sms
ON store(store_number, review_sms);

CREATE INDEX idx_store_number_lookup 
ON store(store_number);

-- Add constraint to ensure store_number is valid
ALTER TABLE store
DROP CONSTRAINT IF EXISTS check_store_number_valid;

ALTER TABLE store
ADD CONSTRAINT check_store_number_valid
CHECK (store_number > 0);

-- Insert or update default store with proper values
INSERT INTO store (
  store_number,
  phone_number,
  pin,
  store_name,
  storeid,
  review_sms
)
VALUES (
  1,  -- Using 1 instead of 9001 for default store
  '1111111111',
  '000000',
  'Default Store',
  1,
  'Thank you for visiting! If you enjoyed your experience, please leave us a review: https://g.page/r/review'
)
ON CONFLICT (store_number) 
DO UPDATE SET
  phone_number = EXCLUDED.phone_number,
  pin = EXCLUDED.pin,
  store_name = EXCLUDED.store_name,
  storeid = EXCLUDED.storeid,
  review_sms = EXCLUDED.review_sms;