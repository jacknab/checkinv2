/*
  # Update Store Configuration Relationship

  1. Changes
    - Remove foreign key constraint from store_config to store
    - Add foreign key from store to store_config instead
    - This allows creating store_config first, then store

  2. Security
    - Maintain existing RLS policies
*/

-- First drop the existing foreign key if it exists
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'fk_store_number'
    AND table_name = 'store_config'
  ) THEN
    ALTER TABLE store_config DROP CONSTRAINT fk_store_number;
  END IF;
END $$;

-- Add foreign key from store to store_config
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'fk_store_config_number'
    AND table_name = 'store'
  ) THEN
    ALTER TABLE store 
    ADD CONSTRAINT fk_store_config_number 
    FOREIGN KEY (store_number) 
    REFERENCES store_config(store_number)
    ON DELETE CASCADE;
  END IF;
END $$;