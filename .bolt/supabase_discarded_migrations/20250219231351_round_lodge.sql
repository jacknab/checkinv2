/*
  # Add test store and fix store verification

  1. Changes
    - Add test store with ID 9001 and PIN 3601
    - Ensure store_number exists and is properly configured
*/

-- First ensure the store_number column exists and is properly configured
ALTER TABLE store
ALTER COLUMN store_number TYPE numeric,
ALTER COLUMN store_number SET NOT NULL;

-- Add the test store
INSERT INTO store (store_number, phone_number, pin, store_name)
VALUES (9001, '0000000000', '3601', 'Test Store')
ON CONFLICT (store_number) 
DO UPDATE SET pin = '3601';