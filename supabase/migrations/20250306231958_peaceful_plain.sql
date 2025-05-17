/*
  # Store Table Setup

  1. New Tables
    - `store`
      - `id` (uuid, primary key)
      - `phone_number` (text, unique)
      - `pin` (numeric)
      - `store_name` (text)
      - `created_at` (timestamp)
      - `store_number` (numeric, unique)
      - `storeid` (numeric)
      - `month_count` (numeric)
      - `review_sms` (text)
      - `checkout_sms` (text)
      - `promo_name` (text)
      - `promo_sms` (text)
      - `promo_trigger` (numeric)

  2. Security
    - Enable RLS on store table
    - Add policies for public and authenticated access
    - Add constraints for data validation

  3. Indexes
    - Create indexes for efficient lookups
*/

-- Create store table
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

-- Create policies
CREATE POLICY "Allow authenticated users to insert store info"
  ON store FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to read store info"
  ON store FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Allow public read access to store"
  ON store FOR SELECT TO public
  USING (true);

CREATE POLICY "Allow public update to store"
  ON store FOR UPDATE TO public
  USING (true);