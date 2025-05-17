/*
  # Add store_number column to store table

  1. Changes
    - Add store_number column to store table if it doesn't exist
    - Ensure store_number is numeric, unique, and not null
    - Add index for better query performance
*/

-- First, ensure we have the store_number column
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'store' AND column_name = 'store_number'
  ) THEN
    ALTER TABLE store ADD COLUMN store_number numeric;
    
    -- Set initial store numbers based on row number
    WITH numbered_stores AS (
      SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) as rnum
      FROM store
    )
    UPDATE store s
    SET store_number = ns.rnum
    FROM numbered_stores ns
    WHERE s.id = ns.id;
    
    -- Make store_number NOT NULL after populating data
    ALTER TABLE store ALTER COLUMN store_number SET NOT NULL;
    
    -- Add unique constraint
    ALTER TABLE store ADD CONSTRAINT store_number_unique UNIQUE (store_number);
  END IF;
END $$;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_store_number 
ON store(store_number);