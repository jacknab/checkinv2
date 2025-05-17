/*
  # Fix storeid column and constraints

  1. Changes
    - Ensure storeid column exists with correct casing
    - Add NOT NULL constraint with default value
    - Add foreign key constraint to store table
  
  2. Security
    - Maintains existing RLS policies
*/

-- First check if either column exists and handle accordingly
DO $$ 
BEGIN
  -- Check for storeID (uppercase)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'check_ins' AND column_name = 'storeID'
  ) THEN
    ALTER TABLE check_ins RENAME COLUMN "storeID" TO storeid;
  END IF;

  -- If neither column exists, add it
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'check_ins' AND column_name = 'storeid'
  ) THEN
    ALTER TABLE check_ins ADD COLUMN storeid numeric;
  END IF;

  -- Set default value and constraints
  ALTER TABLE check_ins
    ALTER COLUMN storeid SET DEFAULT 1,
    ALTER COLUMN storeid SET NOT NULL;

  -- Add foreign key constraint if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'fk_check_ins_store'
  ) THEN
    ALTER TABLE check_ins
    ADD CONSTRAINT fk_check_ins_store
    FOREIGN KEY (storeid) 
    REFERENCES store(store_number);
  END IF;
END $$;