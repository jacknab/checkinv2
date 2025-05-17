/*
  # Fix store configuration
  
  1. New Tables
    - store_config: Stores store configuration and activation status
    
  2. Changes
    - Add unique constraint for store_number
    - Insert default store record
    - Insert default store configuration
    
  3. Security
    - Enable RLS
    - Add policies for public access
*/

-- First ensure we have the proper columns in store table
DO $$ 
BEGIN
  -- Add columns if they don't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'store' AND column_name = 'review_sms'
  ) THEN
    ALTER TABLE store ADD COLUMN review_sms text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'store' AND column_name = 'promo_name'
  ) THEN
    ALTER TABLE store ADD COLUMN promo_name text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'store' AND column_name = 'promo_sms'
  ) THEN
    ALTER TABLE store ADD COLUMN promo_sms text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'store' AND column_name = 'promo_trigger'
  ) THEN
    ALTER TABLE store ADD COLUMN promo_trigger numeric;
  END IF;
END $$;

-- Insert default store if it doesn't exist
INSERT INTO store (
  store_number,
  phone_number,
  pin,
  store_name,
  storeid,
  review_sms,
  promo_name,
  promo_sms,
  promo_trigger
)
SELECT
  9001,
  '0000000000',
  '000000',
  'Default Store',
  9001,
  'Thank you for visiting! If you enjoyed your experience, please leave us a review.',
  'Welcome Bonus',
  'Welcome to our store! Show this message for a special first-time discount.',
  1
WHERE NOT EXISTS (
  SELECT 1 FROM store WHERE store_number = 9001
);

-- Drop existing store_config table if it exists
DROP TABLE IF EXISTS store_config CASCADE;

-- Create store_config table with proper constraints
CREATE TABLE store_config (
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

-- Insert default store configuration
INSERT INTO store_config (store_number, active)
SELECT 9001, true
WHERE NOT EXISTS (
  SELECT 1 FROM store_config WHERE store_number = 9001
);

-- Create optimized indexes
CREATE INDEX IF NOT EXISTS idx_store_number_lookup 
ON store(store_number);

CREATE INDEX IF NOT EXISTS idx_store_promo_trigger
ON store(promo_trigger)
WHERE promo_trigger IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_store_config_lookup
ON store_config(store_number, active);