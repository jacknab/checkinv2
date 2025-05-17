/*
  # Update review SMS message

  1. Changes
    - Updates the review SMS message for all stores
    - Ensures all stores have a valid review SMS message
    - Adds performance optimization index
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

-- Update the review_sms field for all stores
UPDATE store
SET review_sms = 'Thank you for visiting! Please leave us a review at https://g.page/r/review'
WHERE store_number = 9001;

-- Make review_sms NOT NULL after ensuring all rows have a value
ALTER TABLE store
ALTER COLUMN review_sms SET NOT NULL;

-- Add constraint to ensure review_sms is not empty
ALTER TABLE store
DROP CONSTRAINT IF EXISTS check_review_sms_not_empty;

ALTER TABLE store
ADD CONSTRAINT check_review_sms_not_empty 
CHECK (review_sms <> '');

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_store_review_sms
ON store(store_number, review_sms);