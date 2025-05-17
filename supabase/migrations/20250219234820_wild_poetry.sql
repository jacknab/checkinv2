/*
  # Add phone number to checkin list with cleanup

  1. Changes
    - Add phone_number column to checkin_list table
    - Clean up any duplicate active check-ins
    - Create partial unique index for active check-ins
    - Add index for phone number lookups

  2. Security
    - Maintain existing RLS policies
*/

-- First, add the phone_number column without constraints
ALTER TABLE checkin_list
ADD COLUMN IF NOT EXISTS phone_number text;

-- Clean up duplicate active check-ins, keeping only the most recent one
WITH duplicates AS (
  SELECT id,
         ROW_NUMBER() OVER (
           PARTITION BY phone_number, storeid
           ORDER BY checkin_time DESC
         ) as rn
  FROM checkin_list
  WHERE status = 'checked_in'
)
UPDATE checkin_list
SET status = 'checked_out',
    checkout_time = now()
WHERE id IN (
  SELECT id 
  FROM duplicates 
  WHERE rn > 1
);

-- Update existing records with phone numbers from check_ins table
UPDATE checkin_list cl
SET phone_number = ci.phone_number
FROM check_ins ci
WHERE ci.first_name = cl.first_name
AND ci.storeid = cl.storeid
AND cl.phone_number IS NULL;

-- Create a partial unique index that only applies to active check-ins
DROP INDEX IF EXISTS idx_active_checkin_phone;
CREATE UNIQUE INDEX idx_active_checkin_phone
ON checkin_list(phone_number, storeid)
WHERE status = 'checked_in';

-- Create an index for better query performance
CREATE INDEX IF NOT EXISTS idx_checkin_list_phone_number
ON checkin_list(phone_number);