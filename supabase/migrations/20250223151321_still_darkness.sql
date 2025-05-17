/*
  # Fix sendAt column name

  1. Changes
    - Rename sendAt column to sendat in scheduled_sms table to maintain consistency
    - Add index for faster queries on sendat column

  2. Notes
    - This change ensures column naming follows PostgreSQL conventions
    - Improves query performance for SMS scheduling
*/

-- First rename the column if it exists with the wrong case
DO $$ 
BEGIN
  -- Check if the column exists with the wrong case
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'scheduled_sms' AND column_name = 'sendAt'
  ) THEN
    ALTER TABLE scheduled_sms RENAME COLUMN "sendAt" TO sendat;
  END IF;

  -- If neither column exists, add it
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'scheduled_sms' AND column_name = 'sendat'
  ) THEN
    ALTER TABLE scheduled_sms ADD COLUMN sendat timestamptz NOT NULL;
  END IF;
END $$;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_scheduled_sms_sendat 
ON scheduled_sms(sendat, status);