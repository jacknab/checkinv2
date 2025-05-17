/*
  # Add SMS Count Column to Store Table

  1. Changes
    - Add sms_count column to store table
    - Set default value to 0
    - Make column nullable
    - Add index for performance

  2. Purpose
    - Track number of SMS messages sent by each store
    - Enable SMS usage monitoring and reporting
*/

-- Add sms_count column to store table
ALTER TABLE store 
ADD COLUMN IF NOT EXISTS sms_count numeric DEFAULT 0;

-- Create index for sms_count lookups
CREATE INDEX IF NOT EXISTS idx_store_sms_count 
ON store (sms_count) 
WHERE sms_count > 0;