/*
  # Fix Store Relationships

  1. Changes
    - Drop existing foreign key constraints
    - Add correct foreign key from store_config to store
    - Ensure proper relationship direction

  2. Security
    - Maintain existing RLS policies
*/

-- First drop any existing foreign key constraints
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'fk_store_config_number'
    AND table_name = 'store'
  ) THEN
    ALTER TABLE store DROP CONSTRAINT fk_store_config_number;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'fk_store_number'
    AND table_name = 'store_config'
  ) THEN
    ALTER TABLE store_config DROP CONSTRAINT fk_store_number;
  END IF;
END $$;

-- Add foreign key from store_config to store
ALTER TABLE store_config
ADD CONSTRAINT fk_store_number
FOREIGN KEY (store_number)
REFERENCES store(store_number)
ON DELETE CASCADE;