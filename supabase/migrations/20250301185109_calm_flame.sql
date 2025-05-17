/*
  # Create store SMS messages table

  1. New Tables
    - `store_sms_messages`
      - `id` (uuid, primary key)
      - `storeid` (numeric, foreign key to store.store_number)
      - `sms_body` (text, not null)
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS on `store_sms_messages` table
    - Add policies for public access
*/

-- Create store_sms_messages table
CREATE TABLE IF NOT EXISTS store_sms_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  storeid numeric NOT NULL REFERENCES store(store_number),
  sms_body text NOT NULL,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT check_sms_body_not_empty CHECK (sms_body <> '')
);

-- Enable row level security
ALTER TABLE store_sms_messages ENABLE ROW LEVEL SECURITY;

-- Create policies for public access
CREATE POLICY "Allow public read access to store_sms_messages"
  ON store_sms_messages
  FOR SELECT
  TO PUBLIC
  USING (true);

CREATE POLICY "Allow public insert to store_sms_messages"
  ON store_sms_messages
  FOR INSERT
  TO PUBLIC
  WITH CHECK (true);

CREATE POLICY "Allow public update to store_sms_messages"
  ON store_sms_messages
  FOR UPDATE
  TO PUBLIC
  USING (true);

-- Create indexes for better performance
CREATE INDEX idx_store_sms_messages_storeid
ON store_sms_messages(storeid);

-- Insert default message for the default store
INSERT INTO store_sms_messages (storeid, sms_body)
VALUES (
  1,
  'Thank you for visiting! If you enjoyed your experience, please leave us a review: https://g.page/r/review'
)
ON CONFLICT DO NOTHING;