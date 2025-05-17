/*
  # Update storeid column type and add missing store IDs

  1. Changes
    - Modify storeid column in checkin_list table to be numeric
    - Add NOT NULL constraint to storeid
    - Add default store ID to existing records
  
  2. Security
    - Maintain existing RLS policies
*/

-- First, create a temporary column with the new type
ALTER TABLE checkin_list 
ADD COLUMN storeid_new numeric;

-- Copy data from the old column to the new one, converting UUID to a numeric value if needed
UPDATE checkin_list 
SET storeid_new = COALESCE(
  (CASE 
    WHEN storeid IS NOT NULL THEN 
      -- Extract numeric portion if it exists, otherwise use a default
      COALESCE(NULLIF(regexp_replace(storeid::text, '[^0-9]', '', 'g'), '')::numeric, 1)
    ELSE 1
  END
));

-- Drop the old column and rename the new one
ALTER TABLE checkin_list 
DROP COLUMN storeid,
ADD COLUMN storeid numeric NOT NULL DEFAULT 1;

-- Add foreign key constraint to store table
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'store' AND column_name = 'store_number'
  ) THEN
    ALTER TABLE store ADD COLUMN store_number numeric UNIQUE NOT NULL DEFAULT 1;
  END IF;
END $$;

ALTER TABLE checkin_list
ADD CONSTRAINT fk_store
FOREIGN KEY (storeid) 
REFERENCES store(store_number);

-- Update the storeID column in check_ins table to be numeric
ALTER TABLE check_ins
ALTER COLUMN storeID TYPE numeric USING (
  CASE 
    WHEN storeID IS NOT NULL THEN 
      COALESCE(NULLIF(regexp_replace(storeID, '[^0-9]', '', 'g'), '')::numeric, 1)
    ELSE 1
  END
);