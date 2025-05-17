/*
  # Fix column references and constraints

  1. Changes
    - Ensure storeid column exists and has proper constraints
    - Add indexes for better performance
    - Clean up any existing data inconsistencies
*/

-- First, ensure storeid column exists and has proper type
DO $$ 
BEGIN
  -- Add storeid if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'checkin_list' AND column_name = 'storeid'
  ) THEN
    ALTER TABLE checkin_list ADD COLUMN storeid numeric;
  END IF;

  -- Make storeid NOT NULL and add foreign key constraint
  ALTER TABLE checkin_list 
    ALTER COLUMN storeid SET NOT NULL,
    ADD CONSTRAINT fk_checkin_list_store
    FOREIGN KEY (storeid) 
    REFERENCES store(store_number);

  -- Create indexes for better performance
  CREATE INDEX IF NOT EXISTS idx_checkin_list_storeid 
  ON checkin_list(storeid);

  CREATE INDEX IF NOT EXISTS idx_checkin_list_storeid_status 
  ON checkin_list(storeid, status);

  -- Create unique index for active check-ins
  CREATE UNIQUE INDEX IF NOT EXISTS idx_active_checkin_unique
  ON checkin_list(phone_number, storeid)
  WHERE status = 'checked_in' AND phone_number IS NOT NULL;
END $$;