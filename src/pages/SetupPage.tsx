import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { setStoreConfigId } from '../config';
import { Store } from 'lucide-react';

interface StoreForm {
  store_name: string;
  phone_number: string;
  pin: string;
  review_sms: string;
  store_number: string;
  storeid: string;
}

const SetupPage = () => {
  const [storeNumber, setStoreNumber] = useState('');
  const [showStoreForm, setShowStoreForm] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const [storeForm, setStoreForm] = useState<StoreForm>({
    store_name: '',
    phone_number: '',
    pin: '',
    review_sms: 'Thank you for visiting! If you enjoyed your experience, please leave us a review.',
    store_number: '',
    storeid: ''
  });

  const handleStoreNumberSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setMessage(null);

    try {
      const numericStoreNumber = Number(storeNumber);
      if (isNaN(numericStoreNumber) || numericStoreNumber <= 0) {
        throw new Error('Store number must be a positive number');
      }

      // Check if store number already exists
      const { data: existingStore, error: checkError } = await supabase
        .from('store_config')
        .select('*')
        .eq('store_number', numericStoreNumber)
        .maybeSingle();

      if (checkError) throw checkError;
      if (existingStore) {
        throw new Error('Store number already exists');
      }

      // Create new store_config record
      const { error: createError } = await supabase
        .from('store_config')
        .insert({
          store_number: numericStoreNumber,
          active: true
        });

      if (createError) throw createError;

      // Get the created store config ID
      const { data: configData, error: fetchError } = await supabase
        .from('store_config')
        .select('id')
        .eq('store_number', numericStoreNumber)
        .maybeSingle();

      if (fetchError) throw fetchError;
      if (!configData) throw new Error('Failed to fetch store configuration');

      // Store the config ID
      setStoreConfigId(configData.id);

      setStoreForm(prev => ({
        ...prev,
        store_number: storeNumber,
        storeid: storeNumber
      }));
      setShowStoreForm(true);
      setMessage({ type: 'success', text: 'Store configuration created successfully' });
    } catch (error) {
      console.error('Store setup error:', error);
      setMessage({
        type: 'error',
        text: error instanceof Error ? error.message : 'Failed to create store configuration'
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleStoreFormSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setMessage(null);

    try {
      const numericStoreNumber = Number(storeForm.store_number);
      if (isNaN(numericStoreNumber)) {
        throw new Error('Invalid store number');
      }

      // Format phone number
      const formattedPhone = storeForm.phone_number.startsWith('+1')
        ? storeForm.phone_number
        : `+1${storeForm.phone_number.replace(/\D/g, '')}`;

      // Validate phone number
      if (!/^\+1[0-9]{10}$/.test(formattedPhone)) {
        throw new Error('Invalid phone number format');
      }

      // Create store record
      const { error: storeError } = await supabase
        .from('store')
        .insert({
          store_name: storeForm.store_name,
          phone_number: formattedPhone,
          pin: storeForm.pin,
          review_sms: storeForm.review_sms,
          store_number: numericStoreNumber,
          storeid: numericStoreNumber
        });

      if (storeError) throw storeError;

      setMessage({ type: 'success', text: 'Store created successfully' });
      // Reset forms
      setStoreNumber('');
      setShowStoreForm(false);
      setStoreForm({
        store_name: '',
        phone_number: '',
        pin: '',
        review_sms: 'Thank you for visiting! If you enjoyed your experience, please leave us a review.',
        store_number: '',
        storeid: ''
      });
    } catch (error) {
      console.error('Store creation error:', error);
      setMessage({
        type: 'error',
        text: error instanceof Error ? error.message : 'Failed to create store'
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-100 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-7xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Store Setup</h1>
          <Link
            to="/isAdmin/stores"
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 transition-colors"
          >
            <Store size={20} />
            View Stores
          </Link>
        </div>

        {!showStoreForm ? (
          <div className="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
            <form onSubmit={handleStoreNumberSubmit}>
              <div>
                <label htmlFor="store_number" className="block text-sm font-medium text-gray-700">
                  Store Number
                </label>
                <div className="mt-1">
                  <input
                    type="number"
                    id="store_number"
                    value={storeNumber}
                    onChange={(e) => setStoreNumber(e.target.value)}
                    className="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    required
                    min="1"
                    disabled={isLoading}
                  />
                </div>
              </div>

              <div className="mt-6">
                <button
                  type="submit"
                  disabled={isLoading || !storeNumber}
                  className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isLoading ? 'Creating...' : 'Create Store Configuration'}
                </button>
              </div>
            </form>
          </div>
        ) : (
          <div className="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
            <form onSubmit={handleStoreFormSubmit}>
              <div className="space-y-6">
                <div>
                  <label htmlFor="store_name" className="block text-sm font-medium text-gray-700">
                    Store Name
                  </label>
                  <input
                    type="text"
                    id="store_name"
                    value={storeForm.store_name}
                    onChange={(e) => setStoreForm({ ...storeForm, store_name: e.target.value })}
                    className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    required
                  />
                </div>

                <div>
                  <label htmlFor="phone_number" className="block text-sm font-medium text-gray-700">
                    Phone Number
                  </label>
                  <input
                    type="tel"
                    id="phone_number"
                    value={storeForm.phone_number}
                    onChange={(e) => setStoreForm({ ...storeForm, phone_number: e.target.value })}
                    className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    required
                    placeholder="Format: +1XXXXXXXXXX"
                  />
                </div>

                <div>
                  <label htmlFor="pin" className="block text-sm font-medium text-gray-700">
                    PIN
                  </label>
                  <input
                    type="text"
                    id="pin"
                    value={storeForm.pin}
                    onChange={(e) => setStoreForm({ ...storeForm, pin: e.target.value })}
                    className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    required
                    pattern="[0-9]+"
                    maxLength={4}
                  />
                </div>

                <div>
                  <label htmlFor="review_sms" className="block text-sm font-medium text-gray-700">
                    Review SMS Message
                  </label>
                  <textarea
                    id="review_sms"
                    value={storeForm.review_sms}
                    onChange={(e) => setStoreForm({ ...storeForm, review_sms: e.target.value })}
                    rows={3}
                    className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    required
                  />
                </div>

                <button
                  type="submit"
                  disabled={isLoading}
                  className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isLoading ? 'Creating Store...' : 'Create Store'}
                </button>
              </div>
            </form>
          </div>
        )}

        {message && (
          <div className={`mt-4 p-4 rounded-md ${
            message.type === 'success' ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'
          }`}>
            {message.text}
          </div>
        )}
      </div>
    </div>
  );
};

export default SetupPage;