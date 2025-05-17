/*
  # Delete Store Configuration Record for Store 1

  1. Changes
    - Deletes the store configuration record for store number 1
    - Keeps store 9001 configuration intact
    - Ensures proper cleanup

  2. Tables Updated
    - store_config
*/

-- Create a transaction for atomicity
BEGIN;

-- Delete the store configuration record for store 1
DELETE FROM store_config 
WHERE store_number = 1;

-- Create index for better query performance if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_store_config_store_number
ON store_config(store_number)
WHERE active = true;

COMMIT;