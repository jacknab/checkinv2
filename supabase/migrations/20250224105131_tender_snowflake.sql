/*
  # Remove textbelt_id column

  1. Changes
    - Remove the textbelt_id column from scheduled_sms table as we no longer use the TextBelt service
*/

-- Remove textbelt_id column from scheduled_sms table
ALTER TABLE scheduled_sms
DROP COLUMN IF EXISTS textbelt_id;