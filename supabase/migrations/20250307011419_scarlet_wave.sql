/*
  # Add birthday SMS message column to store table

  1. Changes
    - Add `birthday_sms` column to `store` table with default message
    - Column is nullable to allow stores to opt-out of birthday messages

  2. Notes
    - Default message is provided for convenience
    - Existing stores will get the default message
*/

-- Add birthday_sms column with default message
ALTER TABLE store 
ADD COLUMN birthday_sms text 
DEFAULT 'Happy Birthday! 🎉 Thank you for being our valued customer. We hope you have a wonderful day filled with joy and celebration!'::text;

-- Make the column nullable after setting default
ALTER TABLE store 
ALTER COLUMN birthday_sms DROP NOT NULL;