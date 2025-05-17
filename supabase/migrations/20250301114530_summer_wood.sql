/*
  # Fix scheduled_sms table constraints

  1. Changes
    - Add default value for body column
    - Add validation check for body content
    - Add index for better performance
  
  2. Security
    - Maintain existing RLS policies
*/

-- First, ensure body column has proper constraints
ALTER TABLE scheduled_sms
ALTER COLUMN body SET DEFAULT '',
ADD CONSTRAINT check_body_not_empty CHECK (body <> '');

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_scheduled_sms_status_sendat 
ON scheduled_sms(status, sendat)
WHERE status = 'pending';

-- Clean up any existing records with null body
UPDATE scheduled_sms
SET body = ''
WHERE body IS NULL;