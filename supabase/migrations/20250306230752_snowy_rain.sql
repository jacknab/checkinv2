/*
  # Store Configuration Setup

  1. New Tables
    - `store_config`
      - `id` (uuid, primary key)
      - `store_number` (numeric, unique, not null)
      - `active` (boolean, default true)
      - `created_at` (timestamp with time zone, default now())
      - `updated_at` (timestamp with time zone, default now())

  2. Security
    - Enable RLS on `store_config` table
    - Add policies for public access to read/write store_config data

  3. Triggers
    - Add trigger to handle store config insert
*/

-- Create store_config table if it doesn't exist
CREATE TABLE IF NOT EXISTS store_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_number numeric NOT NULL,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT store_config_store_number_key UNIQUE (store_number)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_store_config_lookup ON store_config (store_number, active);
CREATE INDEX IF NOT EXISTS idx_store_config_store_number ON store_config (store_number) WHERE (active = true);

-- Enable RLS
ALTER TABLE store_config ENABLE ROW LEVEL SECURITY;

-- Create RLS policies if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'store_config' 
    AND policyname = 'Allow public read access to store_config'
  ) THEN
    CREATE POLICY "Allow public read access to store_config"
      ON store_config
      FOR SELECT
      TO public
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'store_config' 
    AND policyname = 'Allow public insert to store_config'
  ) THEN
    CREATE POLICY "Allow public insert to store_config"
      ON store_config
      FOR INSERT
      TO public
      WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'store_config' 
    AND policyname = 'Allow public update to store_config'
  ) THEN
    CREATE POLICY "Allow public update to store_config"
      ON store_config
      FOR UPDATE
      TO public
      USING (true);
  END IF;
END $$;

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

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS trigger_store_config_insert ON store_config;
CREATE TRIGGER trigger_store_config_insert
  AFTER INSERT ON store_config
  FOR EACH ROW
  EXECUTE FUNCTION handle_store_config_insert();