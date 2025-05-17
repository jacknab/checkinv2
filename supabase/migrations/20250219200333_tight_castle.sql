/*
  # Create initial tables

  1. New Tables
    - `check_ins`
      - `id` (uuid, primary key)
      - `phone_number` (text, unique)
      - `points` (integer)
      - `storeID` (text)
      - `No_sms` (integer)
      - `check_in_time` (timestamp)
    
    - `store`
      - `id` (uuid, primary key)
      - `phone_number` (text, unique)
      - `pin` (text)
      - `store_name` (text)
      - `created_at` (timestamp)
    
    - `scheduled_sms`
      - `id` (uuid, primary key)
      - `phone_number` (text)
      - `body` (text)
      - `points` (integer)
      - `sendAt` (timestamp)
      - `status` (text)
      - `textbelt_id` (text)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Create check_ins table
CREATE TABLE IF NOT EXISTS check_ins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number text UNIQUE NOT NULL,
  points integer DEFAULT 1,
  storeID text,
  No_sms integer DEFAULT 0,
  check_in_time timestamptz DEFAULT now()
);

ALTER TABLE check_ins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated users to read check_ins"
  ON check_ins
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to insert check_ins"
  ON check_ins
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update check_ins"
  ON check_ins
  FOR UPDATE
  TO authenticated
  USING (true);

-- Create store table
CREATE TABLE IF NOT EXISTS store (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number text UNIQUE NOT NULL,
  pin text NOT NULL,
  store_name text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE store ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated users to read store info"
  ON store
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to insert store info"
  ON store
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Create scheduled_sms table
CREATE TABLE IF NOT EXISTS scheduled_sms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number text NOT NULL,
  body text NOT NULL,
  points integer DEFAULT 1,
  sendAt timestamptz NOT NULL,
  status text DEFAULT 'pending',
  textbelt_id text
);

ALTER TABLE scheduled_sms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated users to read scheduled_sms"
  ON scheduled_sms
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to insert scheduled_sms"
  ON scheduled_sms
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update scheduled_sms"
  ON scheduled_sms
  FOR UPDATE
  TO authenticated
  USING (true);