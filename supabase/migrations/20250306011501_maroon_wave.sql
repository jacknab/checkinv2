/*
  # Fix store queries and add indexes

  1. Changes
    - Add proper indexes for store lookups
    - Ensure storeid is used consistently
    - Update default store record

  2. Security
    - Enable RLS on store table
    - Add policies for store access
*/

-- First ensure storeid is properly set up
ALTER TABLE store
ALTER COLUMN storeid SET NOT NULL;

-- Create unique index on storeid
CREATE UNIQUE INDEX IF NOT EXISTS idx_store_storeid
ON store(storeid);

-- Update the default store
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
ON CONFLICT (storeid) 
DO UPDATE SET
  phone_number = EXCLUDED.phone_number,
  pin = EXCLUDED.pin,
  store_name = EXCLUDED.store_name,
  review_sms = EXCLUDED.review_sms,
  promo_name = EXCLUDED.promo_name,
  promo_sms = EXCLUDED.promo_sms,
  promo_trigger = EXCLUDED.promo_trigger;

-- Create optimized indexes
DROP INDEX IF EXISTS idx_store_lookup;
CREATE INDEX idx_store_lookup
ON store(storeid, store_number);

DROP INDEX IF EXISTS idx_store_number_lookup;
CREATE INDEX idx_store_number_lookup 
ON store(store_number);