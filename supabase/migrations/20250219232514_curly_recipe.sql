/*
  # Fix store verification columns

  1. Changes
    - Ensure storeid is the primary identifier for stores
    - Update verification logic to use storeid and pin
*/

-- First, ensure storeid exists and is set up correctly
DO $$ 
BEGIN
  -- Add storeid if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'store' AND column_name = 'storeid'
  ) THEN
    ALTER TABLE store ADD COLUMN storeid numeric;
  END IF;

  -- Make storeid NOT NULL and UNIQUE if not already
  ALTER TABLE store 
    ALTER COLUMN storeid SET NOT NULL,
    ADD CONSTRAINT store_storeid_unique UNIQUE (storeid);
END $$;