/*
  # Revert storeid columns to numeric type

  1. Changes
    - Revert storeid columns in check_ins and checkin_list tables back to numeric type
    - Update foreign key constraints to reference store.store_number
    - Add store_number column back to store table
    - Ensure all data is preserved during the conversion

  2. Security
    - Maintain existing RLS policies
*/

-- First, add store_number back to store table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'store' AND column_name = 'store_number'
  ) THEN
    ALTER TABLE store ADD COLUMN store_number numeric UNIQUE;
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
  END IF;
END $$;

-- Remove existing foreign key constraints
ALTER TABLE check_ins
DROP CONSTRAINT IF EXISTS fk_check_ins_store;

ALTER TABLE checkin_list
DROP CONSTRAINT IF EXISTS fk_store;

-- Update check_ins table
ALTER TABLE check_ins
DROP COLUMN IF EXISTS storeid CASCADE;

ALTER TABLE check_ins
ADD COLUMN storeid numeric NOT NULL DEFAULT 1;

-- Update checkin_list table
ALTER TABLE checkin_list
DROP COLUMN IF EXISTS storeid CASCADE;

ALTER TABLE checkin_list
ADD COLUMN storeid numeric NOT NULL DEFAULT 1;

-- Add new foreign key constraints
ALTER TABLE check_ins
ADD CONSTRAINT fk_check_ins_store
FOREIGN KEY (storeid) 
REFERENCES store(store_number);

ALTER TABLE checkin_list
ADD CONSTRAINT fk_checkin_list_store
FOREIGN KEY (storeid) 
REFERENCES store(store_number);