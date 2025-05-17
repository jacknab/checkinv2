/*
  # Store Table Setup

  1. New Tables
    - `store`
      - Primary key: id (uuid)
      - Unique constraints on phone_number, store_number, storeid
      - Required fields: phone_number, pin, storeid
      - Optional fields: store_name, month_count, checkout_sms, promo fields
      - Default values for created_at and review_sms

  2. Security
    - Enable RLS
    - Policies for authenticated and public access
    - Constraints for data validation

  3. Indexes
    - Optimized indexes for common queries
    - Special index for promo_trigger when not null
*/

-- Drop existing policies if they exist
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

-- Create store table if it doesn't exist
CREATE TABLE IF NOT EXISTS store (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number text NOT NULL,
  pin numeric NOT NULL,
  store_name text,
  created_at timestamptz DEFAULT now(),
  store_number numeric UNIQUE,
  storeid numeric NOT NULL,
  month_count numeric,
  review_sms text NOT NULL DEFAULT 'Thank you for visiting! If you enjoyed your experience, please leave us a review: https://g.page/r/review',
  checkout_sms text,
  promo_name text,
  promo_sms text,
  promo_trigger numeric,
  CONSTRAINT store_phone_number_key UNIQUE (phone_number),
  CONSTRAINT check_store_number_valid CHECK (store_number > 0),
  CONSTRAINT check_review_sms_not_empty CHECK (review_sms <> '')
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_store_lookup ON store (storeid, store_number);
CREATE INDEX IF NOT EXISTS idx_store_number ON store (store_number);
CREATE INDEX IF NOT EXISTS idx_store_number_lookup ON store (store_number);
CREATE INDEX IF NOT EXISTS idx_store_promo_trigger ON store (promo_trigger) WHERE promo_trigger IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_store_storeid ON store (storeid);

-- Enable RLS
ALTER TABLE store ENABLE ROW LEVEL SECURITY;

-- Create new policies with IF NOT EXISTS
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policy 
    WHERE polrelid = 'store'::regclass 
    AND polname = 'Allow authenticated users to insert store info'
  ) THEN
    CREATE POLICY "Allow authenticated users to insert store info"
      ON store FOR INSERT TO authenticated
      WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policy 
    WHERE polrelid = 'store'::regclass 
    AND polname = 'Allow authenticated users to read store info'
  ) THEN
    CREATE POLICY "Allow authenticated users to read store info"
      ON store FOR SELECT TO authenticated
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policy 
    WHERE polrelid = 'store'::regclass 
    AND polname = 'Allow public read access to store'
  ) THEN
    CREATE POLICY "Allow public read access to store"
      ON store FOR SELECT TO public
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policy 
    WHERE polrelid = 'store'::regclass 
    AND polname = 'Allow public update to store'
  ) THEN
    CREATE POLICY "Allow public update to store"
      ON store FOR UPDATE TO public
      USING (true);
  END IF;
END $$;