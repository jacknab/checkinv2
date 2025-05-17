/*
  # Add SMS Plan Column to Store Table

  1. Changes
    - Add sms_plan column to store table
    - Set default value to 0
    - Make column nullable
    - Add index for performance

  2. Purpose
    - Track SMS plan level for each store
    - Enable SMS plan management and limits
*/

-- Add sms_plan column to store table
ALTER TABLE store 
ADD COLUMN IF NOT EXISTS sms_plan numeric DEFAULT 0;

-- Create index for sms_plan lookups
CREATE INDEX IF NOT EXISTS idx_store_sms_plan 
ON store (sms_plan) 
WHERE sms_plan > 0;