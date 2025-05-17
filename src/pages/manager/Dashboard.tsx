import React, { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';

interface DashboardProps {
  storeId: string;
}

interface DashboardStats {
  todayCheckins: number;
  activeCustomers: number;
  totalPoints: number;
  monthlyStats: { [key: string]: number };
}

const Dashboard: React.FC<DashboardProps> = ({ storeId }) => {
  const [stats, setStats] = useState<DashboardStats>({
    todayCheckins: 0,
    activeCustomers: 0,
    totalSms: 0,
    monthlyStats: {}
  });

  const months = [
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December'
  ];

  useEffect(() => {
    const fetchStats = async () => {
      if (!storeId) {
        console.warn('No store ID provided');
        return;
      }

      const numericStoreId = Number(storeId);
      if (isNaN(numericStoreId)) {
        console.error('Invalid store ID format');
        return;
      }

      try {
        // Get today's check-ins
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const { count: todayCount } = await supabase
          .from('checkin_list')
          .select('*', { count: 'exact', head: true })
          .eq('storeid', numericStoreId)
          .gte('checkin_time', today.toISOString());

        if (todayCount === null) throw new Error('Failed to fetch today\'s check-ins');

        // Get active customers
        const { count: activeCount } = await supabase
          .from('checkin_list')
          .select('*', { count: 'exact', head: true })
          .eq('storeid', numericStoreId)
          .eq('status', 'checked_in');

        if (activeCount === null) throw new Error('Failed to fetch active customers');

        // Get total unique customers count
        const { count: totalCustomers } = await supabase
          .from('check_ins')
          .select('*', { count: 'exact', head: true })
          .eq('storeid', numericStoreId);

        if (totalCustomers === null) throw new Error('Failed to fetch total customers');

        // Get total SMS count
        const { data: store } = await supabase
          .from('store')
          .select('sms_count')
          .eq('store_number', numericStoreId)
          .single();

        const totalSms = store?.sms_count || 0;

        // Get monthly stats for current year
        const currentYear = new Date().getFullYear();
        const startOfYear = new Date(currentYear, 0, 1).toISOString();
        const endOfYear = new Date(currentYear, 11, 31, 23, 59, 59).toISOString();

        const { data: monthlyData } = await supabase
          .from('checkin_list')
          .select('checkin_time')
          .eq('storeid', numericStoreId)
          .gte('checkin_time', startOfYear)
          .lte('checkin_time', endOfYear);

        // Initialize monthly stats
        const monthlyStats = months.reduce((acc, month, index) => {
          acc[month] = 0;
          return acc;
        }, {} as { [key: string]: number });

        // Count check-ins per month
        monthlyData?.forEach(record => {
          const month = new Date(record.checkin_time).getMonth();
          monthlyStats[months[month]]++;
        });

        setStats({
          todayCheckins: todayCount || 0,
          activeCustomers: totalCustomers || 0,
          totalSms,
          monthlyStats
        });
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        console.error('Error fetching dashboard stats:', errorMessage);
        setStats({
          todayCheckins: 0,
          activeCustomers: 0,
          totalSms: 0,
          monthlyStats: {}
        });
      }
    };

    fetchStats();
    // Refresh every minute
    const interval = setInterval(fetchStats, 60000);
    return () => clearInterval(interval);
  }, [storeId]);

  return (
    <div className="space-y-6 w-full">
      <h2 className="text-2xl font-bold text-gray-800">Dashboard</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 w-full">
        <div className="bg-white p-6 rounded-lg shadow w-full">
          <h3 className="text-lg font-semibold text-gray-700">Today's Check-ins</h3>
          <p className="text-3xl font-bold text-indigo-600 mt-2">{stats.todayCheckins}</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow w-full">
          <h3 className="text-lg font-semibold text-gray-700">Total Customers</h3>
          <p className="text-3xl font-bold text-indigo-600 mt-2">{stats.activeCustomers}</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow w-full">
          <h3 className="text-lg font-semibold text-gray-700">SMS Sent</h3>
          <p className="text-3xl font-bold text-indigo-600 mt-2">{stats.totalSms}</p>
        </div>
      </div>
      
      <div className="mt-8 w-full">
        <h3 className="text-xl font-semibold text-gray-800 mb-4">Monthly Check-ins (This Year)</h3>
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 w-full">
          {months.map((month) => (
            <div key={month} className="bg-white p-4 rounded-lg shadow w-full">
              <h4 className="text-sm font-medium text-gray-600">{month}</h4>
              <p className="text-2xl font-bold text-indigo-600 mt-1">
                {stats.monthlyStats[month] || 0}
              </p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
