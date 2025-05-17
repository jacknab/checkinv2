/*
  # Remove textbelt_id column

  1. Changes
    - Remove the unused textbelt_id column from scheduled_sms table
    - This column is no longer needed as we've moved away from the Textbelt SMS service
*/

-- Remove textbelt_id column from scheduled_sms table
ALTER TABLE scheduled_sms
DROP COLUMN IF EXISTS textbelt_id;