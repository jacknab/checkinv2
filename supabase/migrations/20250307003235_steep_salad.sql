/*
  # Update store SMS columns

  1. Changes
    - Set default value of 0 for sms_count column
    - Set default value of 0 for sms_plan column

  2. Purpose
    - Ensure all existing and new records have proper default values for SMS tracking
    - Prevent null values in SMS tracking columns
*/

-- Update existing records to have default values
UPDATE store 
SET sms_count = COALESCE(sms_count, 0),
    sms_plan = COALESCE(sms_plan, 0);

-- Alter columns to set default values and make them not nullable
ALTER TABLE store 
ALTER COLUMN sms_count SET DEFAULT 0,
ALTER COLUMN sms_count SET NOT NULL,
ALTER COLUMN sms_plan SET DEFAULT 0,
ALTER COLUMN sms_plan SET NOT NULL;