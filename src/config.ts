import { supabase } from './lib/supabase';

const STORE_ID_KEY = 'nail_salon_store_id';
const STORE_CONFIG_KEY = 'store_config_id';

// Get API URL from environment or fallback to window.location
const getApiUrl = () => {
  if (import.meta.env.VITE_API_URL) {
    return import.meta.env.VITE_API_URL.trim();
  }
  // Fallback to current origin with port 4000
  const origin = window.location.origin;
  return `${origin.replace(/:\d+$/, '')}:4000`;
};

const API_URL = getApiUrl();

export const getStoreConfigId = (): string => {
  return localStorage.getItem(STORE_CONFIG_KEY) || '';
};

export const setStoreConfigId = (id: string): void => {
  localStorage.setItem(STORE_CONFIG_KEY, id);
};

export const getStoreId = (): string => {
  return localStorage.getItem(STORE_ID_KEY) || '';
};

export const setStoreId = (id: string): void => {
  localStorage.setItem(STORE_ID_KEY, id);
};

// Simple validation without database check
export const validateStoreId = async (storeId: string): Promise<{valid: boolean, storeName?: string, error?: string}> => {
  if (!storeId || storeId.trim() === '') {
    return { valid: false, error: 'Store ID cannot be empty' };
  }
  
  const numericId = Number(storeId);
  if (isNaN(numericId)) {
    return { valid: false, error: 'Store ID must be a number' };
  }

  // Check if store exists in store_config
  const { data: configData, error: configError } = await supabase
    .from('store_config')
    .select('id')
    .eq('store_number', numericId)
    .eq('active', true)
    .maybeSingle();

  if (configError) {
    console.error('Failed to validate store:', configError);
    return { valid: false, error: 'Failed to validate store configuration' };
  }

  if (!configData) {
    return { valid: false, error: 'Store configuration not found' };
  }

  setStoreConfigId(configData.id);
  
  return { valid: true, storeName: `Store #${numericId}` };
};

export const submitPhoneNumber = async (data: {
  phoneNumber: string;
  firstName?: string | null;
  birthMonth?: string | null;
}) => {
  try {
    const storeId = getStoreId();
    if (!storeId) {
      throw new Error('Store configuration required');
    }
    
    // Check if phone number exists
    const { data: existingUser, error: fetchError } = await supabase
      .from('check_ins')
      .select('first_name, birth_month, points, check_in_time, storeid, birthday_trigger') // Added birthday_trigger
      .eq('phone_number', data.phoneNumber)
      .maybeSingle();

    if (fetchError) {
      if (fetchError.code === 'PGRST116') {
        // Record not found, this is fine for new users
        console.log('New user check-in');
      } else {
        console.error('Supabase error:', fetchError);
        throw new Error('Unable to process check-in. Please try again.');
      }
    }

    // First validate the store ID exists
    const numericStoreId = Number(storeId);
    if (isNaN(numericStoreId)) {
      throw new Error('Invalid store ID format');
    }

    // If user exists, update points and return
    if (existingUser) {
      // Get store's promo configuration
      const { data: storeData, error: storeError } = await supabase
        .from('store')
        .select('promo_trigger, promo_sms, promo_name')
        .eq('store_number', numericStoreId)
        .maybeSingle();

      if (storeError) {
        console.error('Failed to fetch store promo config:', storeError);
      }

      // Check if customer points exactly match promo trigger
      const hasPromo = storeData?.promo_trigger && existingUser.points === storeData.promo_trigger;

      // First update the check_ins record
      const { error: updateError } = await supabase
        .from('check_ins')
        .update({ 
          first_name: data.firstName || existingUser.first_name,
          birth_month: data.birthMonth || existingUser.birth_month,
          storeid: numericStoreId,
          check_in_time: new Date().toISOString()
        })
        .eq('phone_number', data.phoneNumber);

      if (updateError) {
        console.error('Failed to update check-in record:', updateError);
        throw new Error('Unable to process check-in. Please try again.');
      }

      // Create new checkin_list record
      const { error: checkinListError } = await supabase
        .from('checkin_list')
        .insert({
          first_name: data.firstName || existingUser.first_name,
          phone_number: data.phoneNumber,
          status: 'checked_in',
          storeid: numericStoreId,
          checkin_time: new Date().toISOString(),
          promo: hasPromo,
          birthday_trigger: existingUser.birthday_trigger // Added birthday_trigger
        });

      if (checkinListError) {
        console.error('Failed to create check-in record:', checkinListError);
        throw new Error('Unable to process check-in. Please try again.');
      }
      
      // Send promo SMS if triggered
      if (hasPromo && storeData?.promo_sms) {
        try {
          await supabase
            .from('scheduled_sms')
            .insert({
              phone_number: data.phoneNumber,
              body: storeData.promo_sms,
              storeid: numericStoreId,
              sendat: new Date().toISOString(),
              status: 'pending'
            });

          // Reset points after triggering promo
          await supabase
            .from('check_ins')
            .update({ points: 0 })
            .eq('phone_number', data.phoneNumber);

          existingUser.points = 0;
        } catch (error) {
          console.error('Failed to schedule promo SMS:', error);
        }
      }

      // Get store's review SMS message if not already fetched
      const { data: reviewData, error: reviewError } = await supabase
        .from('store')
        .select('review_sms')
        .eq('store_number', numericStoreId)
        .maybeSingle();

      if (reviewError) {
        console.error('Failed to fetch store configuration:', reviewError);
        // Continue without SMS if store fetch fails
        return {
          message: 'Welcome back!',
          points: existingUser.points,
          isNewPoint: false
        };
      }
      
      if (reviewData?.review_sms) {
        // Commented out immediate SMS sending
        // const { error: smsError } = await supabase
        //   .from('scheduled_sms')
        //   .insert({
        //     phone_number: data.phoneNumber,
        //     body: storeData.review_sms,
        //     storeid: numericStoreId,
        //     sendat: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
        //     status: 'pending'
        //   });
        //
        // if (smsError) {
        //   console.error('Failed to schedule SMS:', smsError);
        // }
      }

      // Return immediately for existing users
      return {
        message: 'Welcome back!',
        points: existingUser.points || 0,
        isNewPoint: false
      };
    } else if (data.firstName) {
      // New customer logic
      const { error: insertError } = await supabase
        .from('check_ins')
        .insert({
          first_name: data.firstName,
          birth_month: data.birthMonth,
          phone_number: data.phoneNumber,
          storeid: numericStoreId,
          points: 0,
        });

      if (insertError) {
        console.error('Failed to create new user record:', insertError);
        throw new Error('Unable to process check-in. Please try again.');
      }

      // Create new checkin_list record
      const { error: checkinListError } = await supabase
        .from('checkin_list')
        .insert({
          first_name: data.firstName,
          phone_number: data.phoneNumber,
          status: 'checked_in',
          storeid: numericStoreId,
          checkin_time: new Date().toISOString()
        });

      if (checkinListError) {
        console.error('Failed to create check-in record:', checkinListError);
        throw new Error('Unable to process check-in. Please try again.');
      }

      // Get store's review SMS message for new customers
      const { data: storeData, error: storeError } = await supabase
        .from('store')
        .select('review_sms')
        .eq('store_number', numericStoreId)
        .maybeSingle();

      if (storeError) {
        console.error('Failed to fetch store configuration:', storeError);
        // Continue without SMS if store fetch fails
        return {
          message: `Welcome${data.firstName ? ', ' + data.firstName : ''}!`,
          points: 0,
          isNewPoint: false
        };
      }
      
      if (storeData?.review_sms) {
        // Commented out immediate SMS sending
        // const { error: smsError } = await supabase
        //   .from('scheduled_sms')
        //   .insert({
        //     phone_number: data.phoneNumber,
        //     body: storeData.review_sms,
        //     storeid: numericStoreId,
        //     sendat: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
        //     status: 'pending'
        //   });
        //
        // if (smsError) {
        //   console.error('Failed to schedule SMS:', smsError);
        // }
      }

      return {
        message: `Welcome${data.firstName ? ', ' + data.firstName : ''}!`,
        points: 0,
        isNewPoint: false
      };
    }
    
    return {
      message: 'new_user',
      points: 0,
      isNewPoint: false
    };
  } catch (error) {
    // Improve error handling to properly capture and log errors
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
    console.error('Supabase error:', error);
    throw new Error(errorMessage || 'Unable to process check-in. Please try again.');
  }
};

export const checkoutCustomer = async (checkinId: string, employeeId: string) => {
  try {
    const storeId = getStoreId();
    if (!storeId || !checkinId || !employeeId) {
      throw new Error('Store ID, Check-in ID, and Employee ID are required');
    }

    // Convert storeId to numeric
    const numericStoreId = Number(storeId);
    if (isNaN(numericStoreId)) {
      throw new Error('Invalid store ID format');
    }

    // First verify the record exists and is active
    const { data: currentRecord, error: fetchError } = await supabase
      .from('checkin_list')
      .select('status, phone_number')
      .eq('id', checkinId)
      .eq('storeid', numericStoreId)
      .eq('status', 'checked_in')
      .maybeSingle();

    if (fetchError && fetchError.code !== 'PGRST116') {
      throw new Error('Database error while fetching record');
    }

    if (!currentRecord) {
      throw new Error('Check-in record not found or already checked out');
    }

    if (currentRecord) {
      // Check if eligible for new point
      const { data: checkInData, error: checkInError } = await supabase
        .from('check_ins') 
        .select('points')
        .eq('phone_number', currentRecord.phone_number) 
        .maybeSingle();

      if (checkInError && checkInError.code !== 'PGRST116') {
        throw new Error('Failed to fetch check-in data');
      }

      const currentPoints = checkInData?.points || 0;

      // Get store's promo configuration
      const { data: storeData, error: storeError } = await supabase
        .from('store')
        .select('promo_trigger, promo_sms')
        .eq('store_number', numericStoreId)
        .maybeSingle();

      if (storeError) {
        console.error('Failed to fetch store promo config:', storeError);
      }

      // Check if customer has reached promo trigger
      const newPoints = currentPoints + 1;
      const hasPromo = storeData?.promo_trigger && newPoints >= storeData.promo_trigger;

      // Always award a point at checkout
      const { error: pointsError } = await supabase
        .from('check_ins')
        .update({
          // Reset points if promo triggered, otherwise increment
          points: hasPromo ? 0 : newPoints
        })
        .eq('phone_number', currentRecord.phone_number);

      if (pointsError) throw new Error('Failed to update points');

      // Send promo SMS if triggered
      if (hasPromo && storeData?.promo_sms) {
        try {
          await supabase
            .from('scheduled_sms')
            .insert({
              phone_number: currentRecord.phone_number,
              body: storeData.promo_sms,
              storeid: numericStoreId,
              sendat: new Date().toISOString(),
              status: 'pending'
            });
        } catch (error) {
          console.error('Failed to schedule promo SMS:', error);
        }
      }

      // Update the checkin status
      const { error: updateError } = await supabase
        .from('checkin_list')
        .update({
          status: 'checked_out',
          checkout_time: new Date().toISOString(),
          employee_id: employeeId,
          promo: hasPromo,
          birthday_trigger: false  // Add this line to reset birthday trigger
        })
        .match({
          id: checkinId,
          storeid: numericStoreId,
          status: 'checked_in'
        });

      if (updateError) throw new Error('Failed to update check-in status');

      // Send SMS immediately
      try {
        const response = await fetch(`${API_URL}/api/scheduleSms`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          body: JSON.stringify({
            phoneNumber: currentRecord.phone_number,
            immediate: true,
            points: 0,
            storeid: storeId
          })
        });

        if (!response.ok) {
          const errorData = await response.json();
          throw new Error(errorData.error || 'Failed to send SMS');
        }

        await response.json();
      } catch (error) {
        console.error('Failed to send SMS:', error);
        // Don't throw here, just log the error
        // This prevents the checkout from failing if SMS fails
        console.warn('SMS sending failed but continuing with checkout');
      }
      
      return true;
    } else {
      throw new Error('Record is already checked out');
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error during checkout';
    console.error('Checkout error:', errorMessage);
    throw new Error(errorMessage);
  }
};

export const fetchActiveCheckins = async () => {
  try {
    const storeId = getStoreId();
    if (!storeId) {
      console.warn('No store ID found');
      return [];
    }
    
    // Convert storeId to numeric
    const numericStoreId = Number(storeId);
    if (isNaN(numericStoreId)) {
      console.error('Invalid store ID format');
      return [];
    }
    
    console.log(`Fetching checkins for store: ${numericStoreId}`);
    
    // First get all active check-ins
    const { data, error } = await supabase
      .from('checkin_list')
      .select('id, first_name, checkin_time, promo, birthday_trigger') // Added birthday_trigger
      .eq('status', 'checked_in')
      .eq('storeid', numericStoreId)
      .order('checkin_time', { ascending: true })
      .limit(20);

    if (error) {
      console.error('Supabase error fetching check-ins:', error);
      return [];
    }

    console.log(`Found ${data?.length || 0} active check-ins`);
    return data || [];
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : JSON.stringify(error);
    console.error('Failed to fetch active check-ins:', errorMessage);
    return [];
  }
};

export const storeLogin = async (credentials: { phone_number: string; pin: string }) => {
  try {
    const { data, error } = await supabase
      .from('store')
      .select('id, store_name')
      .eq('phone_number', credentials.phone_number)
      .eq('pin', credentials.pin)
      .maybeSingle();

    if (error && error.code !== 'PGRST116') {
      throw error;
    }

    if (!data) {
      return { error: 'Invalid credentials' };
    }

    return {
      message: 'Login successful',
      storeId: data.id,
      storeName: data.store_name
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : JSON.stringify(error);
    console.error('Login error:', errorMessage);
    throw error;
  }
};

// Add this new function alongside your other API functions

export const checkInUser = async (phoneNumber: string, storeId: string) => {
  try {
    // First check if the user already exists
    const { data: existingUser, error: userError } = await supabase
      .from('check_ins')
      .select('first_name, birth_month')
      .eq('phone_number', phoneNumber)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();
    
    // Get store promo details
    const { data: storeData, error: storeError } = await supabase
      .from('store')
      .select('promo_name, promo_trigger')
      .eq('store_number', Number(storeId))
      .single();
    
    // Get customer points
    const { data: customerData, error: customerError } = await supabase
      .from('customer')
      .select('points')
      .eq('phone_number', phoneNumber)
      .single();
    
    // Create a new check-in
    const { data, error } = await supabase
      .from('checkin_list')
      .insert([
        { 
          phone_number: phoneNumber,
          first_name: existingUser?.first_name || 'GUEST',
          store_id: storeId,
          status: 'waiting'
        }
      ])
      .select();
      
    if (error) throw error;
    
    return {
      success: true,
      message: `Check-in successful${existingUser?.first_name ? ': ' + existingUser.first_name : ''}`,
      name: existingUser?.first_name || null,
      birthMonth: existingUser?.birth_month || null,
      points: customerData?.points || 0,
      promoName: storeData?.promo_name || null,
      promoTrigger: storeData?.promo_trigger || 10
    };
  } catch (error) {
    console.error('Check-in error:', error);
    return {
      success: false,
      message: error instanceof Error ? error.message : 'Failed to check in'
    };
  }
};
