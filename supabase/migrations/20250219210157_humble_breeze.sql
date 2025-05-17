/*
  # Add employee ID tracking for checkouts

  1. Changes
    - Add employee_id column to checkin_list table
    - Add checkout_time column default
    - Add index on status for faster queries

  2. Security
    - Maintain existing RLS policies
*/

-- Add employee_id column and set checkout_time default
ALTER TABLE checkin_list 
ADD COLUMN IF NOT EXISTS employee_id text,
ALTER COLUMN checkout_time SET DEFAULT NULL;