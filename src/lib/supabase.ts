import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true
  }
});

// Initialize Supabase client with proper error handling and retries
const initializeSupabase = async () => {
  let retries = 3;
  let connected = false;
  
  while (retries > 0 && !connected) {
    try {
      // Test the connection with simple query
      const { data, error } = await supabase
        .from('store')
        .select('id')
        .limit(1);

      if (error) {
        console.error(`Supabase query error: ${error.message || JSON.stringify(error)}`);
        throw error;
      }
      
      console.log('Supabase connection established successfully');
      connected = true;
      return true;
    } catch (error) {
      // Properly log the error with details
      const errorMsg = error instanceof Error ? error.message : JSON.stringify(error);
      console.error(`Supabase connection attempt failed (${retries} retries left): ${errorMsg}`);
      
      retries--;
      if (retries === 0) {
        console.error('Failed to connect to Supabase after multiple attempts');
        return false;
      }
      
      // Exponential backoff: 1s, 2s, 4s
      const delay = Math.pow(2, 3 - retries) * 1000;
      console.log(`Retrying in ${delay}ms...`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  return connected;
};

// Initialize connection
initializeSupabase().catch(error => {
  const errorMsg = error instanceof Error ? error.message : JSON.stringify(error);
  console.error(`Failed to initialize Supabase: ${errorMsg}`);
});