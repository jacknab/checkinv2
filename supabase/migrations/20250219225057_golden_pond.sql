/*
  # Update store references and column types

  1. Changes
    - Remove foreign key constraints
    - Update column types with proper defaults
    - Add new foreign key constraints
    - Drop store_number column

  2. Security
    - Maintains existing RLS policies
*/

-- First, remove existing foreign key constraints
ALTER TABLE check_ins
DROP CONSTRAINT IF EXISTS fk_check_ins_store;

ALTER TABLE checkin_list
DROP CONSTRAINT IF EXISTS fk_store;

ALTER TABLE store_codes
DROP CONSTRAINT IF EXISTS store_codes_storeid_fkey;

-- Update check_ins table
ALTER TABLE check_ins 
DROP COLUMN storeid,
ADD COLUMN storeid uuid REFERENCES store(id);

-- Update checkin_list table
ALTER TABLE checkin_list
DROP COLUMN storeid,
ADD COLUMN storeid uuid REFERENCES store(id);

-- Update store_codes table
ALTER TABLE store_codes
DROP COLUMN storeid,
ADD COLUMN storeid uuid REFERENCES store(id);

-- Get the default store ID
DO $$ 
DECLARE
  default_store_id uuid;
BEGIN
  SELECT id INTO default_store_id FROM store LIMIT 1;
  
  -- Update all tables to use the default store ID
  UPDATE check_ins SET storeid = default_store_id;
  UPDATE checkin_list SET storeid = default_store_id;
  UPDATE store_codes SET storeid = default_store_id;
  
  -- Now make the columns NOT NULL
  ALTER TABLE check_ins ALTER COLUMN storeid SET NOT NULL;
  ALTER TABLE checkin_list ALTER COLUMN storeid SET NOT NULL;
  ALTER TABLE store_codes ALTER COLUMN storeid SET NOT NULL;
END $$;

-- Drop the store_number column
ALTER TABLE store
DROP COLUMN store_number;