/*
  # Delete Store Configuration Record

  1. Changes
    - Deletes the store configuration record for store 9001
    - Ensures proper cleanup of related data

  2. Tables Updated
    - store_config
*/

-- Create a transaction for atomicity
BEGIN;

-- Delete the store configuration record
DELETE FROM store_config 
WHERE store_number = 9001;

-- Create index for better query performance if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_store_config_store_number
ON store_config(store_number)
WHERE active = true;

COMMIT;