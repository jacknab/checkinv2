/*
  # Update checkin status to use numeric codes

  1. Changes
    - Add status_code column to checkin_list table
    - Update existing records to use numeric codes
    - Add check constraint to ensure valid status codes

  2. Status Codes
    - 0: checked_out
    - 1: checked_in
*/

-- Add status_code column
ALTER TABLE checkin_list 
ADD COLUMN IF NOT EXISTS status_code smallint DEFAULT 1;

-- Update existing records
UPDATE checkin_list
SET status_code = CASE 
  WHEN status = 'checked_out' THEN 0
  WHEN status = 'checked_in' THEN 1
  ELSE 1
END;

-- Add check constraint
ALTER TABLE checkin_list
ADD CONSTRAINT valid_status_code CHECK (status_code IN (0, 1));