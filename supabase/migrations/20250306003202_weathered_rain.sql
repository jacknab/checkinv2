/*
  # Create store configuration table
  
  1. New Tables
    - `store_config`
      - `id` (uuid, primary key)
      - `store_number` (numeric, unique, not null)
      - `active` (boolean, default true)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on store_config table
    - Add policies for public access
*/

-- Create store_config table
CREATE TABLE IF NOT EXISTS store_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_number numeric NOT NULL,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT fk_store_number
    FOREIGN KEY (store_number)
    REFERENCES store(store_number)
    ON DELETE CASCADE
);

-- Create unique index for store_number
CREATE UNIQUE INDEX idx_store_config_store_number
ON store_config(store_number)
WHERE active = true;

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
VALUES (9001, true)
ON CONFLICT DO NOTHING;