/*
  # Fix Store Configuration Relationships

  1. Changes
    - Drop existing foreign key constraints
    - Add correct foreign key from store_config to store
    - Ensure proper relationship direction
    - Add missing indexes
    - Enable RLS

  2. Security
    - Add RLS policies for store_config table
    - Maintain existing security settings
*/

-- First drop any existing foreign key constraints if they exist
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'fk_store_config_number'
    AND table_name = 'store'
  ) THEN
    ALTER TABLE store DROP CONSTRAINT fk_store_config_number;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'fk_store_number'
    AND table_name = 'store_config'
  ) THEN
    ALTER TABLE store_config DROP CONSTRAINT fk_store_number;
  END IF;
END $$;

-- Ensure store_config table exists with correct structure
CREATE TABLE IF NOT EXISTS store_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_number numeric NOT NULL,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT store_config_store_number_key UNIQUE (store_number)
);

-- Add foreign key from store_config to store
ALTER TABLE store_config
ADD CONSTRAINT fk_store_number
FOREIGN KEY (store_number)
REFERENCES store(store_number)
ON DELETE CASCADE;

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_store_config_lookup 
ON store_config (store_number, active);

CREATE INDEX IF NOT EXISTS idx_store_config_store_number 
ON store_config (store_number) 
WHERE (active = true);

-- Enable RLS
ALTER TABLE store_config ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Allow public read access to store_config"
ON store_config FOR SELECT TO public
USING (true);

CREATE POLICY "Allow public insert to store_config"
ON store_config FOR INSERT TO public
WITH CHECK (true);

CREATE POLICY "Allow public update to store_config"
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

  -- Set updated_at on update
  NEW.updated_at := now();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.triggers
    WHERE trigger_name = 'trigger_store_config_insert'
    AND event_object_table = 'store_config'
  ) THEN
    CREATE TRIGGER trigger_store_config_insert
    BEFORE INSERT OR UPDATE ON store_config
    FOR EACH ROW
    EXECUTE FUNCTION handle_store_config_insert();
  END IF;
END $$;