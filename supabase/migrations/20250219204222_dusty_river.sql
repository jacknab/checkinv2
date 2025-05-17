/*
  # Add checkin_list table and update check_ins

  1. New Tables
    - `checkin_list`
      - `id` (uuid, primary key)
      - `first_name` (text)
      - `checkin_time` (timestamptz)
      - `checkout_time` (timestamptz)
      - `storeid` (uuid)
      - `status` (text)

  2. Changes to Existing Tables
    - Add columns to `check_ins`:
      - `first_name` (text)
      - `birth_month` (text)

  3. Security
    - Enable RLS on new table
    - Add policies for public access
*/

-- Create checkin_list table
CREATE TABLE IF NOT EXISTS checkin_list (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name text NOT NULL,
  checkin_time timestamptz DEFAULT now(),
  checkout_time timestamptz,
  storeid uuid REFERENCES store(id),
  status text DEFAULT 'checked_in',
  created_at timestamptz DEFAULT now()
);

-- Enable RLS and add policies for checkin_list
ALTER TABLE checkin_list ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to checkin_list"
  ON checkin_list
  FOR SELECT
  TO PUBLIC
  USING (true);

CREATE POLICY "Allow public insert to checkin_list"
  ON checkin_list
  FOR INSERT
  TO PUBLIC
  WITH CHECK (true);

CREATE POLICY "Allow public update to checkin_list"
  ON checkin_list
  FOR UPDATE
  TO PUBLIC
  USING (true);

-- Add new columns to check_ins table
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'check_ins' AND column_name = 'first_name'
  ) THEN
    ALTER TABLE check_ins ADD COLUMN first_name text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'check_ins' AND column_name = 'birth_month'
  ) THEN
    ALTER TABLE check_ins ADD COLUMN birth_month text;
  END IF;
END $$;