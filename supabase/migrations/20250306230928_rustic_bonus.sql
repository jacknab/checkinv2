/*
  # Update Store and Store Config Relationships

  1. Changes
    - Create temporary table to store existing store numbers
    - Copy store numbers to store_config
    - Add foreign key from store to store_config
    - Handle existing data migration

  2. Security
    - Maintain existing RLS policies
*/

-- Create temporary table to store existing store numbers
CREATE TEMP TABLE temp_store_numbers AS
SELECT DISTINCT store_number FROM store WHERE store_number IS NOT NULL;

-- Insert store numbers into store_config if they don't exist
INSERT INTO store_config (store_number, active)
SELECT store_number, true
FROM temp_store_numbers t
WHERE NOT EXISTS (
  SELECT 1 FROM store_config sc WHERE sc.store_number = t.store_number
);

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

-- Drop temporary table
DROP TABLE temp_store_numbers;