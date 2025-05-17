/*
  # Update Store Table Policies

  1. Changes
    - Drop existing policies
    - Create new policies with proper permissions for public access
    - Allow public to insert new stores
    - Maintain read and update access

  2. Security
    - Enable RLS
    - Policies for authenticated and public access
    - No restrictions on store creation
*/

-- Drop existing policies
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policy 
    WHERE polrelid = 'store'::regclass
  ) THEN
    DROP POLICY IF EXISTS "Allow authenticated users to insert store info" ON store;
    DROP POLICY IF EXISTS "Allow authenticated users to read store info" ON store;
    DROP POLICY IF EXISTS "Allow public read access to store" ON store;
    DROP POLICY IF EXISTS "Allow public update to store" ON store;
  END IF;
END $$;

-- Create new policies with public access
CREATE POLICY "Allow public insert to store"
  ON store FOR INSERT TO public
  WITH CHECK (true);

CREATE POLICY "Allow public read access to store"
  ON store FOR SELECT TO public
  USING (true);

CREATE POLICY "Allow public update to store"
  ON store FOR UPDATE TO public
  USING (true);

-- Ensure RLS is enabled
ALTER TABLE store ENABLE ROW LEVEL SECURITY;