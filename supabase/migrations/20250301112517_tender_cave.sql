/*
  # Fix store ID handling

  1. Changes
    - Add store_number column back to store table
    - Update store_id references to use store_number
    - Add indexes for better performance

  2. Security
    - Maintains existing RLS policies
*/

-- First ensure we have the store_number column
DO $$ 
BEGIN
  -- Add store_number if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'store' AND column_name = 'store_number'
  ) THEN
    ALTER TABLE store ADD COLUMN store_number numeric UNIQUE;
    
    -- Set initial store numbers based on row number
    WITH numbered_stores AS (
      SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) as rnum
      FROM store
    )
    UPDATE store s
    SET store_number = ns.rnum
    FROM numbered_stores ns
    WHERE s.id = ns.id;
    
    -- Make store_number NOT NULL after populating data
    ALTER TABLE store ALTER COLUMN store_number SET NOT NULL;
  END IF;
END $$;

-- Update checkin_list to use store_number
ALTER TABLE checkin_list
DROP CONSTRAINT IF EXISTS fk_checkin_list_store;

ALTER TABLE checkin_list
DROP COLUMN IF EXISTS store_id;

ALTER TABLE checkin_list
ADD COLUMN store_number numeric NOT NULL DEFAULT 1;

-- Add foreign key constraint
ALTER TABLE checkin_list
ADD CONSTRAINT fk_checkin_list_store_number
FOREIGN KEY (store_number) 
REFERENCES store(store_number);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_checkin_list_store_number 
ON checkin_list(store_number);

CREATE INDEX IF NOT EXISTS idx_checkin_list_store_status 
ON checkin_list(store_number, status);

-- Update trigger function to use store_number
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
    WITH updated_checkins AS (
      SELECT id 
      FROM checkin_list 
      WHERE phone_number = NEW.phone_number
        AND store_number = NEW.store_number
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
    WITH old_checkins AS (
      SELECT id 
      FROM checkin_list 
      WHERE store_number = NEW.store_number
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
    RAISE WARNING 'Error in handle_checkin_status: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;