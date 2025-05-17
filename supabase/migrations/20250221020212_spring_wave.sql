/*
  # Database Schema for Nail Salon Check-in System
  
  This migration creates the complete database schema with safety checks.
  
  1. Tables
    - check_ins: Stores customer check-in records and points
    - store: Stores salon information
    - scheduled_sms: Manages SMS scheduling
    - checkin_list: Tracks active check-ins
    - store_codes: Manages employee access codes
    
  2. Security
    - Enables RLS on all tables
    - Creates public access policies
    
  3. Functions and Triggers
    - Auto-checkout for old check-ins
    - Check-in status management
    - Deletion handling
*/

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create tables with IF NOT EXISTS
CREATE TABLE IF NOT EXISTS check_ins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number text UNIQUE NOT NULL,
  first_name text,
  birth_month text,
  points integer DEFAULT 1,
  storeid numeric NOT NULL DEFAULT 1,
  No_sms integer DEFAULT 0,
  check_in_time timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS store (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number text UNIQUE NOT NULL,
  pin text NOT NULL,
  store_name text,
  store_number numeric UNIQUE NOT NULL,
  storeid numeric UNIQUE NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS scheduled_sms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number text NOT NULL,
  body text NOT NULL,
  points integer DEFAULT 1,
  sendAt timestamptz NOT NULL,
  status text DEFAULT 'pending',
  textbelt_id text,
  storeid numeric NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS checkin_list (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name text NOT NULL,
  phone_number text,
  checkin_time timestamptz DEFAULT now(),
  checkout_time timestamptz DEFAULT NULL,
  storeid numeric NOT NULL DEFAULT 1,
  status text DEFAULT 'checked_in' NOT NULL,
  employee_id text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS store_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  storeid numeric NOT NULL,
  store_codes numeric CHECK (store_codes >= 100 AND store_codes <= 999),
  assignTO text,
  inactive integer DEFAULT 0 CHECK (inactive IN (0, 1)),
  IsAdmin integer DEFAULT 0 CHECK (inactive IN (0, 1)),
  created_at timestamptz DEFAULT now(),
  UNIQUE(storeid, store_codes)
);

-- Safely drop existing constraints before adding new ones
DO $$ 
BEGIN
  ALTER TABLE check_ins DROP CONSTRAINT IF EXISTS fk_check_ins_store;
  ALTER TABLE checkin_list DROP CONSTRAINT IF EXISTS fk_checkin_list_store;
  ALTER TABLE store_codes DROP CONSTRAINT IF EXISTS fk_store_codes_store;
EXCEPTION
  WHEN undefined_object THEN NULL;
END $$;

-- Add foreign key constraints
ALTER TABLE check_ins
ADD CONSTRAINT fk_check_ins_store
FOREIGN KEY (storeid) 
REFERENCES store(store_number);

ALTER TABLE checkin_list
ADD CONSTRAINT fk_checkin_list_store
FOREIGN KEY (storeid) 
REFERENCES store(store_number);

ALTER TABLE store_codes
ADD CONSTRAINT fk_store_codes_store
FOREIGN KEY (storeid) 
REFERENCES store(store_number);

-- Safely create indexes
DO $$ 
BEGIN
  -- Drop existing indexes if they exist
  DROP INDEX IF EXISTS idx_check_ins_storeid;
  DROP INDEX IF EXISTS idx_checkin_list_storeid;
  DROP INDEX IF EXISTS idx_store_codes_lookup;
  DROP INDEX IF EXISTS idx_checkin_list_phone_number;
  DROP INDEX IF EXISTS idx_checkin_list_storeid_status;
  DROP INDEX IF EXISTS idx_store_number;
  DROP INDEX IF EXISTS idx_checkin_status_lookup;
  DROP INDEX IF EXISTS idx_active_checkin_unique;
  
  -- Create new indexes
  CREATE INDEX idx_check_ins_storeid ON check_ins(storeid);
  CREATE INDEX idx_checkin_list_storeid ON checkin_list(storeid);
  CREATE INDEX idx_store_codes_lookup ON store_codes(storeid, store_codes);
  CREATE INDEX idx_checkin_list_phone_number ON checkin_list(phone_number);
  CREATE INDEX idx_checkin_list_storeid_status ON checkin_list(storeid, status);
  CREATE INDEX idx_store_number ON store(store_number);
  CREATE INDEX idx_checkin_status_lookup ON checkin_list(phone_number, storeid, status, checkin_time);
  
  -- Create unique index for active check-ins
  CREATE UNIQUE INDEX idx_active_checkin_unique
  ON checkin_list(phone_number, storeid)
  WHERE status = 'checked_in' AND phone_number IS NOT NULL;
EXCEPTION
  WHEN duplicate_table THEN NULL;
END $$;

-- Drop existing functions and triggers
DROP TRIGGER IF EXISTS trigger_handle_checkin_status ON checkin_list;
DROP TRIGGER IF EXISTS trigger_handle_checkin_deletion ON checkin_list;
DROP FUNCTION IF EXISTS handle_checkin_status();
DROP FUNCTION IF EXISTS handle_checkin_deletion();

-- Create function to handle check-in status
CREATE OR REPLACE FUNCTION handle_checkin_status()
RETURNS trigger AS $$
BEGIN
  -- Only proceed if this is a new check-in or status change to checked_in
  IF (TG_OP = 'INSERT' AND NEW.status = 'checked_in') OR 
     (TG_OP = 'UPDATE' AND NEW.status = 'checked_in' AND OLD.status != 'checked_in') THEN
    
    -- Update any existing active check-ins for this phone number at this store
    UPDATE checkin_list
    SET 
      status = 'checked_out',
      checkout_time = CURRENT_TIMESTAMP
    WHERE 
      phone_number = NEW.phone_number
      AND storeid = NEW.storeid
      AND status = 'checked_in'
      AND id != NEW.id;
      
    -- Auto-checkout any check-ins older than 24 hours
    UPDATE checkin_list
    SET 
      status = 'checked_out',
      checkout_time = CURRENT_TIMESTAMP
    WHERE 
      status = 'checked_in'
      AND checkin_time < CURRENT_TIMESTAMP - interval '24 hours'
      AND id != NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create function to handle record deletion
CREATE OR REPLACE FUNCTION handle_checkin_deletion()
RETURNS trigger AS $$
BEGIN
  -- If this is a deletion request
  IF (TG_OP = 'DELETE') THEN
    RETURN OLD;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER trigger_handle_checkin_status
  BEFORE INSERT OR UPDATE ON checkin_list
  FOR EACH ROW
  EXECUTE FUNCTION handle_checkin_status();

CREATE TRIGGER trigger_handle_checkin_deletion
  BEFORE DELETE ON checkin_list
  FOR EACH ROW
  EXECUTE FUNCTION handle_checkin_deletion();

-- Enable row level security
ALTER TABLE check_ins ENABLE ROW LEVEL SECURITY;
ALTER TABLE store ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_sms ENABLE ROW LEVEL SECURITY;
ALTER TABLE checkin_list ENABLE ROW LEVEL SECURITY;
ALTER TABLE store_codes ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DO $$ 
BEGIN
  -- Drop existing policies
  DROP POLICY IF EXISTS "Allow public read access to check_ins" ON check_ins;
  DROP POLICY IF EXISTS "Allow public insert to check_ins" ON check_ins;
  DROP POLICY IF EXISTS "Allow public update to check_ins" ON check_ins;
  DROP POLICY IF EXISTS "Allow public read access to scheduled_sms" ON scheduled_sms;
  DROP POLICY IF EXISTS "Allow public insert to scheduled_sms" ON scheduled_sms;
  DROP POLICY IF EXISTS "Allow public update to scheduled_sms" ON scheduled_sms;
  DROP POLICY IF EXISTS "Allow public read access to checkin_list" ON checkin_list;
  DROP POLICY IF EXISTS "Allow public insert to checkin_list" ON checkin_list;
  DROP POLICY IF EXISTS "Allow public update to checkin_list" ON checkin_list;
  DROP POLICY IF EXISTS "Allow public read access to store_codes" ON store_codes;
  DROP POLICY IF EXISTS "Allow public insert to store_codes" ON store_codes;
  DROP POLICY IF EXISTS "Allow public update to store_codes" ON store_codes;
  
  -- Create new policies
  CREATE POLICY "Allow public read access to check_ins"
    ON check_ins FOR SELECT TO PUBLIC USING (true);
  
  CREATE POLICY "Allow public insert to check_ins"
    ON check_ins FOR INSERT TO PUBLIC WITH CHECK (true);
  
  CREATE POLICY "Allow public update to check_ins"
    ON check_ins FOR UPDATE TO PUBLIC USING (true);
  
  CREATE POLICY "Allow public read access to scheduled_sms"
    ON scheduled_sms FOR SELECT TO PUBLIC USING (true);
  
  CREATE POLICY "Allow public insert to scheduled_sms"
    ON scheduled_sms FOR INSERT TO PUBLIC WITH CHECK (true);
  
  CREATE POLICY "Allow public update to scheduled_sms"
    ON scheduled_sms FOR UPDATE TO PUBLIC USING (true);
  
  CREATE POLICY "Allow public read access to checkin_list"
    ON checkin_list FOR SELECT TO PUBLIC USING (true);
  
  CREATE POLICY "Allow public insert to checkin_list"
    ON checkin_list FOR INSERT TO PUBLIC WITH CHECK (true);
  
  CREATE POLICY "Allow public update to checkin_list"
    ON checkin_list FOR UPDATE TO PUBLIC USING (true);
  
  CREATE POLICY "Allow public read access to store_codes"
    ON store_codes FOR SELECT TO PUBLIC USING (true);
  
  CREATE POLICY "Allow public insert to store_codes"
    ON store_codes FOR INSERT TO PUBLIC WITH CHECK (true);
  
  CREATE POLICY "Allow public update to store_codes"
    ON store_codes FOR UPDATE TO PUBLIC USING (true);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Insert default store if it doesn't exist
INSERT INTO store (store_number, phone_number, pin, store_name, storeid)
VALUES (1, '0000000000', '000000', 'Default Store', 1)
ON CONFLICT (store_number) DO NOTHING;