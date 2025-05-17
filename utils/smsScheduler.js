// Send SMS with proper error handling
const sendSMS = async (phoneNumber, messageBody, client, fromNumber) => {
  try {
    // Validate required parameters
    if (!client || !fromNumber) {
      return { 
        success: false, 
        error: 'SMS service not configured',
        skipped: true 
      };
    }

    if (!phoneNumber || !messageBody) {
      return {
        success: false,
        error: 'Phone number and message body are required',
        skipped: true
      };
    }

    // Format phone number to E.164 format
    const formattedPhone = phoneNumber.startsWith('+1') 
      ? phoneNumber 
      : `+1${phoneNumber.replace(/\D/g, '')}`;

    // Validate phone number format
    if (!/^\+1[0-9]{10}$/.test(formattedPhone)) {
      return {
        success: false,
        error: 'Invalid phone number format',
        skipped: true
      };
    }

    console.log('Sending SMS:', {
      to: formattedPhone,
      from: fromNumber,
      body: messageBody
    });

    const message = await client.messages.create({
      body: messageBody,
      from: fromNumber,
      to: formattedPhone
    });

    console.log('Twilio response:', {
      sid: message.sid,
      status: message.status,
      errorCode: message.errorCode,
      errorMessage: message.errorMessage
    });

    return { success: true, messageId: message.sid };
  } catch (error) {
    console.error('SMS sending error:', {
      code: error.code,
      message: error.message,
      moreInfo: error.moreInfo,
      status: error.status
    });
    const errorMessage = error.code 
      ? `Twilio error: ${error.code}`
      : error.message || 'Failed to send SMS';

    return { 
      success: false, 
      error: errorMessage,
      skipped: false
    };
  }
};

export const processScheduledSms = async (supabase, client, fromNumber) => {
  try {
    if (!client || !fromNumber) {
      return { 
        success: false, 
        error: 'Twilio not configured',
        skipped: true 
      };
    }

    const { data: messages, error } = await supabase
      .from('scheduled_sms')
      .select('*')
      .eq('status', 'pending')
      .lte('sendat', new Date().toISOString());

    if (error) throw error;
    if (!messages || messages.length === 0) return { success: true };

    for (const message of messages) {
      // Skip if phone number or body is missing
      if (!message.phone_number || !message.body) {
        await supabase
          .from('scheduled_sms')
          .update({ 
            status: 'failed',
            error: 'Missing required fields',
            skipped: true
          })
          .eq('id', message.id);
        continue;
      }

      try {
        const result = await sendSMS(message.phone_number, message.body, client, fromNumber);

        console.log('SMS send result:', {
          success: result.success,
          messageId: result.messageId,
          error: result.error,
          skipped: result.skipped
        });

        // If SMS was sent successfully, increment the store's sms_count
        if (result.success) {
          const { error: updateError } = await supabase
            .from('store')
            .update({ 
              sms_count: supabase.sql`sms_count + 1` 
            })
            .eq('store_number', message.storeid);

          if (updateError) {
            console.error('Failed to update SMS count:', updateError);
          }
        }

        await supabase
          .from('scheduled_sms')
          .update({ 
            status: result.success ? 'sent' : 'failed',
            error: result.error,
            message_id: result.messageId,
            skipped: result.skipped || false,
            last_attempt: new Date().toISOString(),
            retry_count: message.retry_count + 1,
            last_error: result.error || null
          })
          .eq('id', message.id);

        if (result.success) {
          console.log(`SMS sent successfully to ${message.phone_number}`);
        } else {
          if (result.skipped) {
            console.warn(`SMS skipped for ${message.phone_number} - service not configured`);
          } else {
            console.warn(`SMS failed for ${message.phone_number}:`, result.error);
          }
        }
      } catch (error) {
        console.error(`Failed to send SMS to ${message.phone_number}:`, error.message);
        const { error: updateError } = await supabase
          .from('scheduled_sms')
          .update({ 
            status: 'failed',
            error: error.message || 'Unknown error',
            skipped: false,
            last_attempt: new Date().toISOString(),
            retry_count: message.retry_count + 1,
            last_error: error.message || 'Unknown error'
          })
          .eq('id', message.id);
      }
    }

    return { success: true };
  } catch (error) {
    console.error('Error processing scheduled SMS:', error.message);
    return { 
      success: false, 
      error: error.message || 'Failed to process scheduled SMS'
    };
  }
};