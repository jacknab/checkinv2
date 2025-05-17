/*
  # Update default store configuration

  1. Changes
    - Updates existing store with ID 9001 with default review SMS message
    - Ensures proper review_sms column exists
    - Maintains existing store data while updating necessary fields
*/

-- First, ensure we have the review_sms column
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'store' AND column_name = 'review_sms'
  ) THEN
    ALTER TABLE store
    ADD COLUMN review_sms text NOT NULL 
    DEFAULT 'Thank you for visiting! If you enjoyed your experience, please leave us a review: https://g.page/r/review';
  END IF;
END $$;

-- Update existing store with ID 9001
UPDATE store
SET 
  store_name = COALESCE(store_name, 'Default Store'),
  review_sms = 'Thank you for visiting! If you enjoyed your experience, please leave us a review: https://g.page/r/review'
WHERE store_number = 9001;

-- Create index for faster lookups if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_store_number_lookup 
ON store(store_number);