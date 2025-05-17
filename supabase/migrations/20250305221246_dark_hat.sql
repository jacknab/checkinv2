/*
  # Add promotion columns to store table

  1. New Columns
    - `promo_name` (text, nullable) - Name of the promotion
    - `promo_sms` (text, nullable) - SMS message for the promotion
    - `promo_trigger` (numeric, nullable) - Trigger value for the promotion

  2. Changes
    - Add three new nullable columns to the store table
    - Set default values to NULL for all new columns
*/

-- Add promotion-related columns to store table
ALTER TABLE store
ADD COLUMN promo_name text DEFAULT NULL,
ADD COLUMN promo_sms text DEFAULT NULL,
ADD COLUMN promo_trigger numeric DEFAULT NULL;

-- Create index for better query performance
CREATE INDEX idx_store_promo_trigger
ON store(promo_trigger)
WHERE promo_trigger IS NOT NULL;