import React, { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';

interface SettingsProps {
  storeId: string;
}

interface StoreSettings {
  store_name: string;
  phone_number: string;
  review_sms: string;
  promo_name: string | null;
  promo_sms: string | null;
  promo_trigger: number | null;
}

const Settings: React.FC<SettingsProps> = ({ storeId }) => {
  const [settings, setSettings] = useState<StoreSettings>({
    store_name: '',
    phone_number: '',
    review_sms: 'Thank you for visiting! If you enjoyed your experience, please leave us a review.',
    promo_name: null,
    promo_sms: null,
    promo_trigger: null
  });
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState('');

  useEffect(() => {
    const fetchSettings = async () => {
      if (!storeId) return;

      const numericStoreId = Number(storeId);
      if (isNaN(numericStoreId)) {
        console.error('Invalid store ID format');
        return;
      }

      try {
        const { data, error } = await supabase
          .from('store')
          .select('store_name, phone_number, review_sms, promo_name, promo_sms, promo_trigger')
          .eq('store_number', numericStoreId)
          .single();

        if (error) throw error;
        if (data) {
          setSettings(data);
        }
        setMessage('');
      } catch (error) {
        console.error('Error fetching store settings:', error);
        setMessage('Failed to load store settings');
      }
    };

    fetchSettings();
  }, [storeId]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setMessage('');

    try {
      const numericStoreId = Number(storeId);
      if (isNaN(numericStoreId)) {
        throw new Error('Invalid store ID format');
      }

      const { error } = await supabase
        .from('store')
        .update({
          store_name: settings.store_name?.trim() || '',
          phone_number: settings.phone_number?.trim() || '',
          review_sms: settings.review_sms?.trim() || 'Thank you for visiting!',
          promo_name: settings.promo_name?.trim() || null,
          promo_sms: settings.promo_sms?.trim() || null,
          promo_trigger: settings.promo_trigger || null
        }) 
        .eq('store_number', numericStoreId);

      if (error) throw error;
      setMessage('Settings updated successfully');
    } catch (error) {
      console.error('Error updating settings:', error);
      setMessage(error instanceof Error ? error.message : 'Failed to update settings');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-gray-800">Settings</h2>
      <div className="bg-white rounded-lg shadow">
        <form className="p-6" onSubmit={handleSubmit}>
          <h3 className="text-lg font-semibold text-gray-700 mb-4">Store Configuration</h3>
          <div className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700">Store Name</label>
              <input
                type="text"
                value={settings.store_name}
                onChange={(e) => setSettings({ ...settings, store_name: e.target.value })}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
                placeholder="Enter store name"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Phone Number</label>
              <input
                type="text"
                value={settings.phone_number}
                onChange={(e) => setSettings({ ...settings, phone_number: e.target.value })}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
                placeholder="Enter phone number"
                required
                pattern="[0-9]{10}"
              />
              <p className="mt-1 text-sm text-gray-500">Enter 10 digits without spaces or special characters</p>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Review SMS Message</label>
              <textarea
                rows={3}
                value={settings.review_sms}
                onChange={(e) => setSettings({ ...settings, review_sms: e.target.value })}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
                placeholder="Enter review SMS message"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Promotion Name</label>
              <input
                type="text"
                value={settings.promo_name || ''}
                onChange={(e) => setSettings({ ...settings, promo_name: e.target.value || null })}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
                placeholder="Enter promotion name"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Promotion Message</label>
              <textarea
                rows={3}
                value={settings.promo_sms || ''}
                onChange={(e) => setSettings({ ...settings, promo_sms: e.target.value || null })}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
                placeholder="Enter promotion message"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Points Trigger</label>
              <input
                type="number"
                value={settings.promo_trigger || ''}
                onChange={(e) => setSettings({ ...settings, promo_trigger: e.target.value ? Number(e.target.value) : null })}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
                placeholder="Enter points required to trigger promotion"
                min="0"
              />
            </div>
            <button
              type="submit"
              disabled={isLoading}
              className="w-full bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200"
            >
              {isLoading ? 'Saving...' : 'Save Settings'}
            </button>
            {message && (
              <p className={`mt-4 text-sm text-center font-medium ${message.includes('Failed') ? 'text-red-600' : 'text-green-600'}`}>
                {message}
              </p>
            )}
          </div>
        </form>
      </div>
    </div>
  );
};

export default Settings;