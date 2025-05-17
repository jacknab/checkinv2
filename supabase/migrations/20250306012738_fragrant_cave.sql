/*
  # Add Store Config Trigger

  1. New Trigger
    - Creates a trigger to automatically create a store record when a new store_config is created
    - Copies store_number to storeid in the store table
    - Sets default values for required fields

  2. Security
    - Maintains existing RLS policies
    - Ensures data consistency between tables
*/

-- Create function to handle store creation
CREATE OR REPLACE FUNCTION handle_store_config_insert()
RETURNS trigger AS $$
BEGIN
  -- Insert new store record
  INSERT INTO store (
    store_number,
    storeid,
    phone_number,
    pin,
    store_name,
    review_sms
  ) VALUES (
    NEW.store_number,
    NEW.store_number,  -- Use store_number as storeid
    '0000000000',     -- Default phone
    '000000',         -- Default PIN
    'New Store',      -- Default name
    'Thank you for visiting! If you enjoyed your experience, please leave us a review.'  -- Default review message
  )
  ON CONFLICT (store_number) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_store_config_insert ON store_config;
CREATE TRIGGER trigger_store_config_insert
  AFTER INSERT ON store_config
  FOR EACH ROW
  EXECUTE FUNCTION handle_store_config_insert();

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_store_config_store_number
ON store_config(store_number)
WHERE active = true;