/*
  # Fix store table structure

  1. Changes
    - Add storeid column to store table
    - Ensure proper column types and constraints
    - Update existing data
*/

-- First, add storeid column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'store' AND column_name = 'storeid'
  ) THEN
    ALTER TABLE store ADD COLUMN storeid numeric UNIQUE;
    
    -- Set storeid equal to store_number for existing records
    UPDATE store 
    SET storeid = store_number;
    
    -- Make storeid NOT NULL
    ALTER TABLE store ALTER COLUMN storeid SET NOT NULL;
  END IF;
END $$;