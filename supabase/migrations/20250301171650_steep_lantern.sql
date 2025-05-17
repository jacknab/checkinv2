/*
  # Add review SMS column to store table

  1. Changes
    - Add `review_sms` column to store table for storing custom review messages
    - Set default review message for existing stores
    - Add constraint to ensure review_sms is not empty

  2. Notes
    - Default message is set for better user experience
    - NOT NULL constraint ensures every store has a review message
*/

-- Add review_sms column with default message
ALTER TABLE store
ADD COLUMN review_sms text NOT NULL 
DEFAULT 'Thank you for visiting! If you enjoyed your experience, please leave us a review: https://g.page/r/review';

-- Add constraint to ensure review_sms is not empty
ALTER TABLE store
ADD CONSTRAINT check_review_sms_not_empty 
CHECK (review_sms <> '');