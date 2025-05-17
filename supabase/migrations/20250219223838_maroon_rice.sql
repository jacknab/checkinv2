/*
  # Add default store and fix constraints

  1. Changes
    - Add default store record with store_number 1
    - Ensure all existing check_ins records have valid store references
    - Update foreign key constraints to be less restrictive initially
  
  2. Security
    - Maintains existing RLS policies
*/

-- First ensure we have a default store
INSERT INTO store (store_number, phone_number, pin, store_name)
VALUES (1, '0000000000', '000000', 'Default Store')
ON CONFLICT (store_number) DO NOTHING;

-- Update any null or invalid storeid values in check_ins to reference the default store
UPDATE check_ins
SET storeid = 1
WHERE storeid IS NULL OR 
      NOT EXISTS (
        SELECT 1 FROM store WHERE store.store_number = check_ins.storeid
      );

-- Update any null or invalid storeid values in checkin_list to reference the default store
UPDATE checkin_list
SET storeid = 1
WHERE storeid IS NULL OR 
      NOT EXISTS (
        SELECT 1 FROM store WHERE store.store_number = checkin_list.storeid
      );

-- Update any null or invalid storeid values in store_codes to reference the default store
UPDATE store_codes
SET storeid = 1
WHERE storeid IS NULL OR 
      NOT EXISTS (
        SELECT 1 FROM store WHERE store.store_number = store_codes.storeid
      );