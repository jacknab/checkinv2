import React, { useState } from 'react';
import { supabase } from '../../lib/supabase';
import { getStoreId } from '../../config';

const STOP_MESSAGE = "\n\nTo stop receiving messages, reply STOP.";
const MAX_SMS_LENGTH = 160;

interface BulkSMSProps {
  storeId: string;
}

const BulkSMS: React.FC<BulkSMSProps> = ({ storeId }) => {
  const [message, setMessage] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [status, setStatus] = useState<{ type: 'success' | 'error', message: string } | null>(null);
  const [remainingChars, setRemainingChars] = useState(MAX_SMS_LENGTH - STOP_MESSAGE.length);

  const handleMessageChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const newMessage = e.target.value;
    const remaining = MAX_SMS_LENGTH - (newMessage.length + STOP_MESSAGE.length);
    if (remaining >= 0) {
      setMessage(newMessage);
      setRemainingChars(remaining);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setStatus(null);

    try {
      const numericStoreId = Number(storeId);
      if (isNaN(numericStoreId)) {
        throw new Error('Invalid store ID');
      }

      const fullMessage = message.trim() + STOP_MESSAGE;

      // Get all unique phone numbers from check_ins for this store
      const { data: customers, error: fetchError } = await supabase
        .from('check_ins')
        .select('phone_number')
        .eq('storeid', numericStoreId)
        .not('phone_number', 'is', null);

      if (fetchError) throw fetchError;
      if (!customers?.length) {
        setStatus({ type: 'error', message: 'No customers found' });
        return;
      }

      // Create scheduled SMS records for each customer
      const scheduledMessages = customers.map(customer => ({
        phone_number: customer.phone_number,
        body: fullMessage,
        storeid: numericStoreId,
        sendat: new Date().toISOString(),
        status: 'pending'
      }));

      const { error: insertError } = await supabase
        .from('scheduled_sms')
        .insert(scheduledMessages);

      if (insertError) throw insertError;

      setStatus({
        type: 'success',
        message: `Messages scheduled for ${customers.length} customers`
      });
      setMessage('');
    } catch (error) {
      console.error('Bulk SMS error:', error);
      setStatus({
        type: 'error',
        message: error instanceof Error ? error.message : 'Failed to schedule messages'
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-gray-800">Bulk SMS</h2>
      <div className="bg-white rounded-lg shadow">
        <form className="p-6" onSubmit={handleSubmit}>
          <h3 className="text-lg font-semibold text-gray-700 mb-4">Send Mass Message</h3>
          <div className="space-y-4">
            <div>
              <div className="flex justify-between items-center mb-2">
                <label className="block text-sm font-medium text-gray-700">Message</label>
                <span className={`text-sm ${remainingChars < 20 ? 'text-red-600' : 'text-gray-500'}`}>
                  {remainingChars} characters remaining
                </span>
              </div>
              <textarea
                value={message}
                onChange={handleMessageChange}
                rows={8}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                placeholder="Enter your message"
                required
                disabled={isLoading}
              />
              <p className="mt-2 text-sm text-gray-500">
                Note: "{STOP_MESSAGE}" will be automatically appended to your message
              </p>
            </div>
            <button
              type="submit"
              disabled={isLoading || !message.trim() || !getStoreId()}
              className="w-full bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200"
            >
              {isLoading ? 'Scheduling Messages...' : 'Send Mass Message'}
            </button>
            {status && (
              <p className={`text-sm text-center font-medium ${
                status.type === 'success' ? 'text-green-600' : 'text-red-600'
              }`}>
                {status.message}
              </p>
            )}
          </div>
        </form>
      </div>
    </div>
  );
};

export default BulkSMS;