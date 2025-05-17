/*
  # Update store configuration and add review SMS

  1. Changes
    - Adds review_sms column if it doesn't exist
    - Updates existing store with review SMS message
    - Preserves existing store data
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

-- Update the review_sms field for all stores that don't have it set
UPDATE store
SET review_sms = COALESCE(
  review_sms,
  'Thank you for visiting! If you enjoyed your experience, please leave us a review: https://g.page/r/review'
);

-- Make review_sms NOT NULL after ensuring all rows have a value
ALTER TABLE store
ALTER COLUMN review_sms SET NOT NULL;

-- Create index for faster lookups if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_store_lookup 
ON store(store_number, review_sms);