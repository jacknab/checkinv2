/*
  # Create default store

  1. Changes
    - Ensures default store with ID 9001 exists
    - Sets proper default values
    - Updates indexes for better performance

  2. Security
    - No changes to RLS policies
*/

-- First ensure we have the proper columns
DO $$ 
BEGIN
  -- Add columns if they don't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'store' AND column_name = 'review_sms'
  ) THEN
    ALTER TABLE store ADD COLUMN review_sms text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'store' AND column_name = 'promo_name'
  ) THEN
    ALTER TABLE store ADD COLUMN promo_name text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'store' AND column_name = 'promo_sms'
  ) THEN
    ALTER TABLE store ADD COLUMN promo_sms text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'store' AND column_name = 'promo_trigger'
  ) THEN
    ALTER TABLE store ADD COLUMN promo_trigger numeric;
  END IF;
END $$;

-- Insert or update the default store with ID 9001
INSERT INTO store (
  store_number,
  phone_number,
  pin,
  store_name,
  storeid,
  review_sms,
  promo_name,
  promo_sms,
  promo_trigger
)
VALUES (
  9001,
  '0000000000',
  '000000',
  'Default Store',
  9001,
  'Thank you for visiting! If you enjoyed your experience, please leave us a review.',
  'Welcome Bonus',
  'Welcome to our store! Show this message for a special first-time discount.',
  1
)
ON CONFLICT (store_number) 
DO UPDATE SET
  phone_number = EXCLUDED.phone_number,
  pin = EXCLUDED.pin,
  store_name = EXCLUDED.store_name,
  storeid = EXCLUDED.storeid,
  review_sms = EXCLUDED.review_sms,
  promo_name = EXCLUDED.promo_name,
  promo_sms = EXCLUDED.promo_sms,
  promo_trigger = EXCLUDED.promo_trigger;

-- Create optimized indexes
DROP INDEX IF EXISTS idx_store_number_lookup;
CREATE INDEX idx_store_number_lookup 
ON store(store_number);

DROP INDEX IF EXISTS idx_store_promo_trigger;
CREATE INDEX idx_store_promo_trigger
ON store(promo_trigger)
WHERE promo_trigger IS NOT NULL;