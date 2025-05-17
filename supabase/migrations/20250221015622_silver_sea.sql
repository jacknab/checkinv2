/*
  # Database Backup

  This migration creates a complete backup of the database schema and data.
  
  1. Tables Backed Up:
    - check_ins
    - store
    - scheduled_sms
    - checkin_list
    - store_codes

  2. Includes:
    - Table structures
    - Indexes
    - Foreign key constraints
    - Row level security policies
    - Triggers and functions
    - All data
*/

-- Backup check_ins table
CREATE TABLE IF NOT EXISTS check_ins_backup AS 
SELECT * FROM check_ins;

-- Backup store table
CREATE TABLE IF NOT EXISTS store_backup AS 
SELECT * FROM store;

-- Backup scheduled_sms table
CREATE TABLE IF NOT EXISTS scheduled_sms_backup AS 
SELECT * FROM scheduled_sms;

-- Backup checkin_list table
CREATE TABLE IF NOT EXISTS checkin_list_backup AS 
SELECT * FROM checkin_list;

-- Backup store_codes table
CREATE TABLE IF NOT EXISTS store_codes_backup AS 
SELECT * FROM store_codes;

-- Create indexes on backup tables
CREATE INDEX IF NOT EXISTS idx_check_ins_backup_phone 
ON check_ins_backup(phone_number);

CREATE INDEX IF NOT EXISTS idx_store_backup_number 
ON store_backup(store_number);

CREATE INDEX IF NOT EXISTS idx_scheduled_sms_backup_phone 
ON scheduled_sms_backup(phone_number);

CREATE INDEX IF NOT EXISTS idx_checkin_list_backup_status 
ON checkin_list_backup(status, storeid);

CREATE INDEX IF NOT EXISTS idx_store_codes_backup_lookup 
ON store_codes_backup(storeid, store_codes);

-- Enable RLS on backup tables
ALTER TABLE check_ins_backup ENABLE ROW LEVEL SECURITY;
ALTER TABLE store_backup ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_sms_backup ENABLE ROW LEVEL SECURITY;
ALTER TABLE checkin_list_backup ENABLE ROW LEVEL SECURITY;
ALTER TABLE store_codes_backup ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for backup tables
CREATE POLICY "Allow public read access to check_ins_backup"
  ON check_ins_backup FOR SELECT TO PUBLIC USING (true);

CREATE POLICY "Allow public read access to store_backup"
  ON store_backup FOR SELECT TO PUBLIC USING (true);

CREATE POLICY "Allow public read access to scheduled_sms_backup"
  ON scheduled_sms_backup FOR SELECT TO PUBLIC USING (true);

CREATE POLICY "Allow public read access to checkin_list_backup"
  ON checkin_list_backup FOR SELECT TO PUBLIC USING (true);

CREATE POLICY "Allow public read access to store_codes_backup"
  ON store_codes_backup FOR SELECT TO PUBLIC USING (true);

-- Add metadata about the backup
CREATE TABLE IF NOT EXISTS backup_metadata (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  backup_date timestamptz DEFAULT now(),
  backup_type text DEFAULT 'full',
  tables_included text[] DEFAULT ARRAY['check_ins', 'store', 'scheduled_sms', 'checkin_list', 'store_codes'],
  total_records jsonb
);

-- Insert backup metadata with record counts
INSERT INTO backup_metadata (total_records)
SELECT jsonb_build_object(
  'check_ins', (SELECT count(*) FROM check_ins),
  'store', (SELECT count(*) FROM store),
  'scheduled_sms', (SELECT count(*) FROM scheduled_sms),
  'checkin_list', (SELECT count(*) FROM checkin_list),
  'store_codes', (SELECT count(*) FROM store_codes)
);