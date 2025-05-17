/*
  # Add SMS Count Update Cron Function

  1. New Function
    - Creates a function to update store SMS counts
    - Counts all scheduled SMS records for each store
    - Updates store.sms_count with the total count

  2. Cron Job
    - Creates a cron job to run every minute
    - Calls the update function automatically
*/

-- Create function to update SMS counts
CREATE OR REPLACE FUNCTION update_store_sms_counts()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Update sms_count for each store based on their scheduled_sms records
  UPDATE store s
  SET sms_count = COALESCE(counts.total_sms, 0)
  FROM (
    SELECT storeid, COUNT(*) as total_sms
    FROM scheduled_sms
    WHERE status = 'sent'
    GROUP BY storeid
  ) counts
  WHERE s.store_number = counts.storeid;
END;
$$;

-- Create cron job to run the update function every minute
SELECT cron.schedule(
  'update-store-sms-counts',  -- job name
  '* * * * *',               -- every minute
  'SELECT update_store_sms_counts()'
);