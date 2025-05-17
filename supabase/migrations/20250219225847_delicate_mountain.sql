/*
  # Update store_codes table to use numeric storeid

  1. Changes
    - Update store_codes table to use numeric storeid type
    - Add foreign key constraint to reference store.store_number
    - Ensure data consistency with other tables

  2. Security
    - Maintain existing RLS policies
*/

-- Remove existing foreign key constraint
ALTER TABLE store_codes
DROP CONSTRAINT IF EXISTS store_codes_storeid_fkey;

-- Update store_codes table
ALTER TABLE store_codes
DROP COLUMN IF EXISTS storeid CASCADE;

ALTER TABLE store_codes
ADD COLUMN storeid numeric NOT NULL DEFAULT 1;

-- Add new foreign key constraint
ALTER TABLE store_codes
ADD CONSTRAINT fk_store_codes_store
FOREIGN KEY (storeid) 
REFERENCES store(store_number);

-- Recreate the index for faster lookups
DROP INDEX IF EXISTS idx_store_codes_lookup;
CREATE INDEX idx_store_codes_lookup 
ON store_codes(storeid, store_codes);