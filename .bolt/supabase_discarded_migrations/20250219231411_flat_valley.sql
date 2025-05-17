/*
  # Add test store and fix store verification

  1. Changes
    - Add test store with ID 9001 and PIN 3601
*/

-- Add the test store if it doesn't exist
INSERT INTO store (store_number, phone_number, pin, store_name)
VALUES (9001, '0000000000', '3601', 'Test Store')
ON CONFLICT (store_number) 
DO UPDATE SET pin = '3601';