/*
  # Fix storeid columns to be numeric type

  1. Changes
    - Ensure all storeid columns are numeric type
    - Re-establish foreign key constraints
    - Set proper default values

  2. Security
    - Maintain existing RLS policies
*/

-- First ensure we have a default store
INSERT INTO store (store_number, phone_number, pin, store_name)
VALUES (1, '0000000000', '000000', 'Default Store')
ON CONFLICT (store_number) DO NOTHING;

-- Remove existing foreign key constraints
ALTER TABLE check_ins
DROP CONSTRAINT IF EXISTS fk_check_ins_store;

ALTER TABLE checkin_list
DROP CONSTRAINT IF EXISTS fk_checkin_list_store;

ALTER TABLE store_codes
DROP CONSTRAINT IF EXISTS fk_store_codes_store;

-- Fix check_ins table
ALTER TABLE check_ins
DROP COLUMN IF EXISTS storeid CASCADE;

ALTER TABLE check_ins
ADD COLUMN storeid numeric NOT NULL DEFAULT 1;

-- Fix checkin_list table
ALTER TABLE checkin_list
DROP COLUMN IF EXISTS storeid CASCADE;

ALTER TABLE checkin_list
ADD COLUMN storeid numeric NOT NULL DEFAULT 1;

-- Fix store_codes table
ALTER TABLE store_codes
DROP COLUMN IF EXISTS storeid CASCADE;

ALTER TABLE store_codes
ADD COLUMN storeid numeric NOT NULL DEFAULT 1;

-- Add foreign key constraints
ALTER TABLE check_ins
ADD CONSTRAINT fk_check_ins_store
FOREIGN KEY (storeid) 
REFERENCES store(store_number);

ALTER TABLE checkin_list
ADD CONSTRAINT fk_checkin_list_store
FOREIGN KEY (storeid) 
REFERENCES store(store_number);

ALTER TABLE store_codes
ADD CONSTRAINT fk_store_codes_store
FOREIGN KEY (storeid) 
REFERENCES store(store_number);

-- Recreate indexes for better performance
CREATE INDEX IF NOT EXISTS idx_check_ins_storeid ON check_ins(storeid);
CREATE INDEX IF NOT EXISTS idx_checkin_list_storeid ON checkin_list(storeid);
DROP INDEX IF EXISTS idx_store_codes_lookup;
CREATE INDEX idx_store_codes_lookup ON store_codes(storeid, store_codes);