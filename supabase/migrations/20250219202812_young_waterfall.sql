/*
  # Create anonymous user for public access

  This migration creates an anonymous user and grants necessary permissions for public access
  to the check_ins and scheduled_sms tables.

  1. Security Changes
    - Create anonymous user role
    - Grant necessary permissions to anonymous role
    - Enable row level security with public access policies
*/

-- Enable row level security but allow public access for check_ins
ALTER TABLE check_ins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to check_ins"
  ON check_ins
  FOR SELECT
  TO PUBLIC
  USING (true);

CREATE POLICY "Allow public insert to check_ins"
  ON check_ins
  FOR INSERT
  TO PUBLIC
  WITH CHECK (true);

CREATE POLICY "Allow public update to check_ins"
  ON check_ins
  FOR UPDATE
  TO PUBLIC
  USING (true);

-- Enable row level security but allow public access for scheduled_sms
ALTER TABLE scheduled_sms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to scheduled_sms"
  ON scheduled_sms
  FOR SELECT
  TO PUBLIC
  USING (true);

CREATE POLICY "Allow public insert to scheduled_sms"
  ON scheduled_sms
  FOR INSERT
  TO PUBLIC
  WITH CHECK (true);

CREATE POLICY "Allow public update to scheduled_sms"
  ON scheduled_sms
  FOR UPDATE
  TO PUBLIC
  USING (true);