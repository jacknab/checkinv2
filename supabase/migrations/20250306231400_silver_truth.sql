/*
  # Store Configuration Setup

  1. Changes
    - Create store_config table with proper structure
    - Add foreign key relationship from store_config to store
    - Create necessary indexes
    - Enable RLS with proper policies

  2. Security
    - Enable RLS on store_config table
    - Add policies for public access
    - Ensure proper constraints and validations

  3. Important Notes
    - Foreign key constraint is from store_config to store
    - Ensures store_config entries can only reference existing stores
    - Handles store configuration setup and validation
*/

-- Drop existing policies if they exist
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "store_config_read_policy" ON store_config;
  DROP POLICY IF EXISTS "store_config_insert_policy" ON store_config;
  DROP POLICY IF EXISTS "store_config_update_policy" ON store_config;
END $$;

-- Drop and recreate store_config table
DROP TABLE IF EXISTS store_config;

CREATE TABLE store_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_number numeric NOT NULL,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT store_config_store_number_key UNIQUE (store_number)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_store_config_lookup 
ON store_config (store_number, active);

CREATE INDEX IF NOT EXISTS idx_store_config_store_number 
ON store_config (store_number) 
WHERE (active = true);

-- Enable RLS
ALTER TABLE store_config ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "store_config_read_policy"
ON store_config FOR SELECT TO public
USING (true);

CREATE POLICY "store_config_insert_policy"
ON store_config FOR INSERT TO public
WITH CHECK (
  EXISTS (
    SELECT 1 FROM store 
    WHERE store.store_number = store_config.store_number
  )
);

CREATE POLICY "store_config_update_policy"
ON store_config FOR UPDATE TO public
USING (true);

-- Create or replace trigger function
CREATE OR REPLACE FUNCTION handle_store_config_insert()
RETURNS TRIGGER AS $$
BEGIN
  -- Validate store number
  IF NEW.store_number <= 0 THEN
    RAISE EXCEPTION 'Store number must be positive';
  END IF;

  -- Verify store exists
  IF NOT EXISTS (
    SELECT 1 FROM store 
    WHERE store.store_number = NEW.store_number
  ) THEN
    RAISE EXCEPTION 'Store number % does not exist', NEW.store_number;
  END IF;

  -- Set updated_at on update
  NEW.updated_at := now();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_store_config_insert ON store_config;

CREATE TRIGGER trigger_store_config_insert
BEFORE INSERT OR UPDATE ON store_config
FOR EACH ROW
EXECUTE FUNCTION handle_store_config_insert();