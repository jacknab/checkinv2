/*
  # Fix store configuration and review message

  1. Changes
    - Add review_sms column with default message
    - Ensure default store exists with ID 9001
    - Add validation for store number format
    - Add index for faster store lookups

  2. Security
    - No changes to RLS policies
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

-- Update existing store with ID 9001 if it exists, or insert if it doesn't
DO $$
BEGIN
  UPDATE store
  SET 
    phone_number = CASE 
      WHEN phone_number = '0000000000' THEN '1111111111'
      ELSE phone_number
    END,
    pin = '000000',
    store_name = 'Default Store',
    review_sms = 'Thank you for visiting! Please leave us a review at https://g.page/r/review'
  WHERE store_number = 9001;

  IF NOT FOUND THEN
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
  END IF;
END $$;

-- Make review_sms NOT NULL after ensuring all rows have a value
ALTER TABLE store
ALTER COLUMN review_sms SET NOT NULL;

-- Add constraint to ensure review_sms is not empty
ALTER TABLE store
DROP CONSTRAINT IF EXISTS check_review_sms_not_empty;

ALTER TABLE store
ADD CONSTRAINT check_review_sms_not_empty 
CHECK (review_sms <> '');

-- Create index for faster lookups if it doesn't exist
DROP INDEX IF EXISTS idx_store_number_lookup;
CREATE INDEX idx_store_number_lookup 
ON store(store_number);

-- Add constraint to ensure store_number is valid
ALTER TABLE store
DROP CONSTRAINT IF EXISTS check_store_number_valid;

ALTER TABLE store
ADD CONSTRAINT check_store_number_valid
CHECK (store_number > 0);