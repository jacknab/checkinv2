/*
  # Fix checkin list storeid handling

  1. Changes
    - Ensure storeid column in checkin_list is properly configured
    - Add index for better performance
*/

-- First ensure the storeid column is properly configured
ALTER TABLE checkin_list
ALTER COLUMN storeid TYPE numeric USING storeid::numeric;

-- Create index for better performance if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_checkin_list_storeid_status 
ON checkin_list(storeid, status);