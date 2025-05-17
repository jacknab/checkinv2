/*
  # Create store codes table

  1. New Tables
    - `store_codes`
      - `id` (uuid, primary key)
      - `storeid` (numeric, foreign key to store.store_number)
      - `store_codes` (numeric, 3 digits)
      - `assignTO` (text)
      - `inactive` (integer, default 0)
      - `IsAdmin` (integer, default 0)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on `store_codes` table
    - Add policies for authenticated and public access
    - Add unique constraint for store_codes per store
*/

-- Create store_codes table
CREATE TABLE IF NOT EXISTS store_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  storeid numeric NOT NULL REFERENCES store(store_number),
  store_codes numeric CHECK (store_codes >= 100 AND store_codes <= 999),
  assignTO text,
  inactive integer DEFAULT 0 CHECK (inactive IN (0, 1)),
  IsAdmin integer DEFAULT 0 CHECK (inactive IN (0, 1)),
  created_at timestamptz DEFAULT now(),
  UNIQUE(storeid, store_codes)
);

-- Enable row level security
ALTER TABLE store_codes ENABLE ROW LEVEL SECURITY;

-- Create policies for public access
CREATE POLICY "Allow public read access to store_codes"
  ON store_codes
  FOR SELECT
  TO PUBLIC
  USING (true);

CREATE POLICY "Allow public insert to store_codes"
  ON store_codes
  FOR INSERT
  TO PUBLIC
  WITH CHECK (true);

CREATE POLICY "Allow public update to store_codes"
  ON store_codes
  FOR UPDATE
  TO PUBLIC
  USING (true);

-- Create index for faster lookups
CREATE INDEX idx_store_codes_lookup 
ON store_codes(storeid, store_codes);