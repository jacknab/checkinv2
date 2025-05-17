/*
  # Fix storeid column in checkin_list table

  1. Changes
    - Add store_id column to checkin_list table
    - Migrate data from storeid to store_id if it exists
    - Update foreign key constraints
    - Update indexes

  2. Security
    - Maintains existing RLS policies
*/

-- First, check if we need to migrate data
DO $$ 
BEGIN
  -- Add store_id column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'checkin_list' AND column_name = 'store_id'
  ) THEN
    ALTER TABLE checkin_list ADD COLUMN store_id uuid;
  END IF;

  -- If old storeid column exists, migrate data and drop it
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'checkin_list' AND column_name = 'storeid'
  ) THEN
    -- Migrate data from storeid to store_id
    UPDATE checkin_list cl
    SET store_id = s.id
    FROM store s
    WHERE cl.storeid::text = s.store_number::text;

    -- Drop old column
    ALTER TABLE checkin_list DROP COLUMN storeid;
  END IF;

  -- Make store_id NOT NULL and add foreign key constraint
  ALTER TABLE checkin_list 
    ALTER COLUMN store_id SET NOT NULL,
    ADD CONSTRAINT fk_checkin_list_store
    FOREIGN KEY (store_id) 
    REFERENCES store(id);

  -- Create indexes for better performance
  CREATE INDEX IF NOT EXISTS idx_checkin_list_store_id 
  ON checkin_list(store_id);

  CREATE INDEX IF NOT EXISTS idx_checkin_list_store_status 
  ON checkin_list(store_id, status);
END $$;

-- Update the trigger function to use store_id instead of storeid
CREATE OR REPLACE FUNCTION handle_checkin_status()
RETURNS trigger AS $$
BEGIN
  -- Validate input
  IF NEW.phone_number IS NULL THEN
    RETURN NEW;
  END IF;

  -- Only proceed if this is a new check-in or status change to checked_in
  IF (TG_OP = 'INSERT' AND NEW.status = 'checked_in') OR 
     (TG_OP = 'UPDATE' AND NEW.status = 'checked_in' AND 
      (OLD.status IS NULL OR OLD.status != 'checked_in')) THEN
    
    -- Update any existing active check-ins for this phone number at this store
    -- Use a CTE for better performance
    WITH updated_checkins AS (
      SELECT id 
      FROM checkin_list 
      WHERE phone_number = NEW.phone_number
        AND store_id = NEW.store_id
        AND status = 'checked_in'
        AND id != NEW.id
      FOR UPDATE SKIP LOCKED
    )
    UPDATE checkin_list cl
    SET 
      status = 'checked_out',
      checkout_time = CURRENT_TIMESTAMP
    FROM updated_checkins uc
    WHERE cl.id = uc.id;

    -- Auto-checkout any check-ins older than 24 hours for this store
    -- Use a separate CTE for better performance
    WITH old_checkins AS (
      SELECT id 
      FROM checkin_list 
      WHERE store_id = NEW.store_id
        AND status = 'checked_in'
        AND checkin_time < CURRENT_TIMESTAMP - interval '24 hours'
        AND id != NEW.id
      FOR UPDATE SKIP LOCKED
    )
    UPDATE checkin_list cl
    SET 
      status = 'checked_out',
      checkout_time = CURRENT_TIMESTAMP
    FROM old_checkins oc
    WHERE cl.id = oc.id;
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error if needed
    RAISE WARNING 'Error in handle_checkin_status: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;