/*
  # Store Configuration Update
  
  1. Changes
    - Creates store_config table if it doesn't exist
    - Adds proper constraints and indexes
    - Handles existing store data safely
    - Updates references to use proper store IDs
  
  2. Security
    - Enables RLS on store_config table
    - Adds policies for public access
*/

-- Create store_config table if it doesn't exist
CREATE TABLE IF NOT EXISTS store_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_number numeric UNIQUE NOT NULL,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT fk_store_number
    FOREIGN KEY (store_number)
    REFERENCES store(store_number)
    ON DELETE CASCADE
);

-- Enable row level security
ALTER TABLE store_config ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Allow public read access to store_config" ON store_config;
  DROP POLICY IF EXISTS "Allow public insert to store_config" ON store_config;
  DROP POLICY IF EXISTS "Allow public update to store_config" ON store_config;
END $$;

-- Create policies for public access
CREATE POLICY "Allow public read access to store_config"
  ON store_config
  FOR SELECT
  TO PUBLIC
  USING (true);

CREATE POLICY "Allow public insert to store_config"
  ON store_config
  FOR INSERT
  TO PUBLIC
  WITH CHECK (true);

CREATE POLICY "Allow public update to store_config"
  ON store_config
  FOR UPDATE
  TO PUBLIC
  USING (true);

-- Create optimized indexes
DROP INDEX IF EXISTS idx_store_config_lookup;
CREATE INDEX idx_store_config_lookup
ON store_config(store_number, active);

-- First ensure we have a store with ID 1
INSERT INTO store (
  store_number,
  phone_number,
  pin,
  store_name,
  storeid,
  review_sms
)
SELECT
  1,
  '1111111111',
  '000000',
  'Default Store',
  1,
  'Thank you for visiting! If you enjoyed your experience, please leave us a review.'
WHERE NOT EXISTS (
  SELECT 1 FROM store WHERE store_number = 1
);

-- Now we can safely update references and create store config
UPDATE check_ins SET storeid = 1 WHERE storeid = 9001;
UPDATE checkin_list SET storeid = 1 WHERE storeid = 9001;
UPDATE scheduled_sms SET storeid = 1 WHERE storeid = 9001;
UPDATE store_codes SET storeid = 1 WHERE storeid = 9001;

-- Insert store config for store 1
INSERT INTO store_config (store_number, active)
SELECT 1, true
WHERE NOT EXISTS (
  SELECT 1 FROM store_config WHERE store_number = 1
);

-- Now we can safely remove store 9001 if it exists
DELETE FROM store WHERE store_number = 9001;