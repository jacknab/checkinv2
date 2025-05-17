import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';
import twilio from 'twilio';
import { processScheduledSms } from './utils/smsScheduler.js';

// Load environment variables
dotenv.config();

// Initialize Supabase client
const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

// Initialize Twilio client
const twilioClient = process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN
  ? twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN)
  : null;
const fromNumber = process.env.TWILIO_PHONE_NUMBER || null;

// Create Express app
const app = express();
const PORT = process.env.PORT || 4000;

// Middleware
app.use(cors({
  origin: '*', // Allow all origins for development
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  credentials: true
}));
app.use(express.json());

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok',
    time: new Date().toISOString(),
    supabase: !!supabase,
    twilio: !!twilioClient
  });
});

// API routes
app.post('/api/scheduleSms', async (req, res) => {
  try {
    const { phoneNumber, immediate, points, storeid } = req.body;
    
    if (!phoneNumber) {
      return res.status(400).json({ error: 'Phone number is required' });
    }

    // Format phone number to E.164 format
    const formattedPhone = phoneNumber.startsWith('+1') 
      ? phoneNumber 
      : `+1${phoneNumber.replace(/\D/g, '')}`;

    // If immediate is true, send SMS right away
    if (immediate && twilioClient && fromNumber) {
      try {
        // Fetch store's review SMS message
        const { data: storeData, error: storeError } = await supabase 
          .from('store')
          .select('review_sms, promo_trigger, promo_sms')
          .eq('store_number', Number(storeid))
          .maybeSingle();

        if (storeError) {
          console.error('Supabase error fetching store:', storeError);
          return res.status(500).json({ error: 'Failed to fetch store message' });
        }

        // Check if customer has reached promo trigger points
        if (storeData.promo_trigger) {
          const { data: customerData, error: customerError } = await supabase
            .from('check_ins')
            .select('points')
            .eq('phone_number', formattedPhone)
            .maybeSingle();

          if (customerError) {
            console.error('Failed to fetch customer points:', customerError);
          } else if (customerData?.points === storeData.promo_trigger && storeData.promo_sms) {
            // Reset points to 0 first
            const { error: resetError } = await supabase
              .from('check_ins')
              .update({ points: 0 })
              .eq('phone_number', formattedPhone);

            if (resetError) {
              console.error('Failed to reset points:', resetError);
            }

            // Send promo SMS immediately
            try {
              await twilioClient.messages.create({
                body: storeData.promo_sms,
                from: fromNumber,
                to: formattedPhone
              });

              // Increment SMS count
              const { error: updateError } = await supabase
                .from('store')
                .update({ 
                  sms_count: supabase.sql`sms_count + 1` 
                })
                .eq('store_number', Number(storeid));

              if (updateError) {
                console.error('Failed to update SMS count for promo:', updateError);
              }
            } catch (error) {
              console.error('Failed to send promo SMS:', error);
            }
          }
        }

        const messageBody = storeData?.review_sms || 
          'Thank you for visiting! Please leave us a review.';

        try {
          const message = await twilioClient.messages.create({
            body: messageBody,
            from: fromNumber,
            to: formattedPhone
          });

          // Increment SMS count for the store
          const { error: updateError } = await supabase
            .from('store')
            .update({ 
              sms_count: supabase.sql`sms_count + 1` 
            })
            .eq('store_number', Number(storeid));

          if (updateError) {
            console.error('Failed to update SMS count:', updateError);
          }

          return res.json({ 
            success: true, 
            messageId: message.sid,
            message: 'SMS sent successfully'
          });
        } catch (error) {
          console.error('Twilio error:', error);
          return res.status(500).json({ 
            error: `Failed to send SMS: ${error.message || 'Unknown error'}` 
          });
        }
      } catch (error) {
        console.error('Failed to process SMS:', error);
        return res.status(500).json({ error: 'Internal server error' });
      }
    } else {
      // Otherwise, mark it for processing later
      res.json({ 
        success: true, 
        message: 'SMS scheduled successfully'
      });
    }
  } catch (error) {
    console.error('Error scheduling SMS:', error);
    res.status(500).json({ error: 'Failed to schedule SMS' });
  }
});

// Process scheduled SMS messages
const runSmsProcessor = async () => {
  try {
    console.log('Running SMS processor at', new Date().toISOString());
    const result = await processScheduledSms(supabase, twilioClient, fromNumber);
    if (!result.success) {
      console.error('SMS processor error:', result.error);
    } else {
      console.log('SMS processor completed successfully');
    }
  } catch (error) {
    console.error('Failed to process scheduled SMS:', error);
  }
};

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`API URL: ${process.env.VITE_API_URL || 'Not configured'}`);
  console.log(`Twilio configured: ${!!twilioClient}`);
  
  // Run SMS processor once at startup
  runSmsProcessor();
  
  // Then schedule to run every minute
  setInterval(runSmsProcessor, 60000);
});

export const submitPhoneNumber = async (phoneNumber, storeId) => {
  try {
    // Check if this is a returning customer
    const { data: existingUser } = await supabase
      .from('customers')
      .select('*')
      .eq('phone', phoneNumber)
      .eq('store_id', storeId)
      .single();
      
    if (existingUser) {
      // Existing customer logic
      
      // Check if this is a guest (no name provided previously)
      const isGuest = !existingUser.first_name || existingUser.first_name === 'GUEST';
      
      // Return appropriate response
      return {
        success: true,
        isGuest: isGuest, // Flag to identify guest check-ins
        message: isGuest ? "Thanks for checking in!" : "Welcome back!",
        points: existingUser.points || 0,
        promoTrigger: existingUser.promo_trigger || 0,
        promoName: existingUser.promo_name || null
      };
    } else {
      // New customer
      // Create customer record
      const { error } = await supabase.from('customers').insert({
        phone: phoneNumber,
        store_id: storeId,
        created_at: new Date().toISOString(),
        points: 1, // Starting points
      });
      
      if (error) throw error;
      
      // For new customers, we'll ask for their name by default
      return {
        success: true,
        isGuest: false, // Not treating new customers as guests by default
        message: "Welcome! Please enter your name.",
        points: 1
      };
    }
  } catch (error) {
    console.error('Error:', error);
    return { success: false, message: "Error processing your request." };
  }
};