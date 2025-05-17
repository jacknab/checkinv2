import React, { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';

interface DailyCheckoutsProps {
  storeId: string;
}

interface Checkout {
  id: string;
  first_name: string;
  phone_number: string;
  checkin_time: string;
  checkout_time: string;
}

const DailyCheckouts: React.FC<DailyCheckoutsProps> = ({ storeId }) => {
  const [checkouts, setCheckouts] = useState<Checkout[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchDailyCheckouts = async () => {
      if (!storeId) return;

      setIsLoading(true);
      setError(null);

      try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const { data, error: fetchError } = await supabase
          .from('checkin_list')
          .select('id, first_name, phone_number, checkin_time, checkout_time')
          .eq('storeid', Number(storeId))
          .eq('status', 'checked_out')
          .gte('checkout_time', today.toISOString())
          .order('checkout_time', { ascending: false });

        if (fetchError) throw fetchError;
        setCheckouts(data || []);
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : 'Failed to fetch checkouts';
        setError(errorMessage);
        console.error('Error fetching daily checkouts:', err);
      } finally {
        setIsLoading(false);
      }
    };

    fetchDailyCheckouts();
    // Refresh every minute
    const interval = setInterval(fetchDailyCheckouts, 60000);
    return () => clearInterval(interval);
  }, [storeId]);

  const formatTime = (dateString: string) => {
    return new Date(dateString).toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    });
  };

  const formatPhoneNumber = (phone: string) => {
    const cleaned = phone.replace(/\D/g, '').slice(-10);
    return `(${cleaned.slice(0, 3)}) ${cleaned.slice(3, 6)}-${cleaned.slice(6)}`;
  };

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-gray-800">Today's Checkouts</h2>
      
      {error && (
        <div className="bg-red-50 text-red-700 p-4 rounded-md">
          {error}
        </div>
      )}

      <div className="bg-white shadow rounded-lg overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Name
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Phone Number
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Check-in Time
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Checkout Time
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {isLoading ? (
                <tr>
                  <td colSpan={4} className="px-6 py-4 text-center text-gray-500">
                    Loading...
                  </td>
                </tr>
              ) : checkouts.length === 0 ? (
                <tr>
                  <td colSpan={4} className="px-6 py-4 text-center text-gray-500">
                    No checkouts found for today
                  </td>
                </tr>
              ) : (
                checkouts.map((checkout) => (
                  <tr key={checkout.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {checkout.first_name}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {formatPhoneNumber(checkout.phone_number)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {formatTime(checkout.checkin_time)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {formatTime(checkout.checkout_time)}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default DailyCheckouts;