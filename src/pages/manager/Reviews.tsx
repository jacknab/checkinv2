import React, { useState, useEffect } from 'react';
import { Routes, Route, NavLink, useLocation } from 'react-router-dom';
import { Menu, X, LayoutDashboard, MessageSquare, ClipboardCheck, Star } from 'lucide-react'; // Add Star for the Reviews icon
import { getStoreId } from '../config';

// Import manager page components
import Dashboard from './manager/Dashboard';
import BulkSMS from './manager/BulkSMS';
import DailyCheckouts from './manager/DailyCheckouts';

const ManagerPage = () => {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [storeId, setStoreId] = useState<string>('');
  const location = useLocation();

  useEffect(() => {
    const id = getStoreId();
    if (!id) {
      // Redirect to home if no store ID is set
      window.location.href = '/';
    } else {
      setStoreId(id);
    }
  }, []);

  const navigation = [
    { name: 'Dashboard', path: '/manager', icon: LayoutDashboard, exact: true },
    { name: 'Bulk SMS', path: '/manager/bulk-sms', icon: MessageSquare },
    { name: 'Daily Checkouts', path: '/manager/checkouts', icon: ClipboardCheck },
    { name: 'Reviews', path: `/reviews/${storeId}`, icon: Star } // New link for Reviews
  ];

  const isActive = (path: string) => {
    if (path === '/manager') {
      return location.pathname === path;
    }
    return location.pathname.startsWith(path);
  };

  return (
    <div className="flex h-screen bg-gray-100">
      {/* Mobile menu button */}
      <button
        className="lg:hidden fixed top-4 left-4 z-50 p-2 rounded-md bg-white shadow-lg"
        onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
      >
        {isMobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
      </button>

      {/* Sidebar */}
      <div
        className={`
          fixed lg:static inset-y-0 left-0 z-40
          transform lg:transform-none transition-transform duration-300
          ${isMobileMenuOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
          w-64 bg-white shadow-lg
        `}
      >
        <div className="flex flex-col h-full">
          <div className="flex items-center justify-center h-16 px-4 border-b">
            <h1 className="text-xl font-bold text-gray-800">Manager Portal</h1>
          </div>
          <nav className="flex-1 px-4 py-4 space-y-1">
            {navigation.map((item) => (
              <NavLink
                key={item.name}
                to={item.path}
                end={item.exact}
                className={({ isActive }) => `
                  flex items-center px-4 py-3 text-sm font-medium rounded-lg
                  ${isActive ? 
                    'bg-indigo-50 text-indigo-700' : 
                    'text-gray-700 hover:bg-gray-50'
                  }
                `}
                onClick={() => setIsMobileMenuOpen(false)}
              >
                <item.icon className="w-5 h-5 mr-3" />
                {item.name}
              </NavLink>
            ))}
          </nav>
        </div>
      </div>

      {/* Main content */}
      <div className="flex-1 overflow-auto">
        <div className="container mx-auto px-4 py-8">
          <Routes>
            <Route path="/" element={<Dashboard storeId={storeId} />} />
            <Route path="/bulk-sms" element={<BulkSMS storeId={storeId} />} />
            <Route path="/checkouts" element={<DailyCheckouts storeId={storeId} />} />
            <Route path="/reviews" element={<Reviews StoreId={storeId} />} />
          </Routes>
        </div>
      </div>

      {/* Mobile overlay */}
      {isMobileMenuOpen && (
        <div 
          className="fixed inset-0 bg-black bg-opacity-50 z-30 lg:hidden"
          onClick={() => setIsMobileMenuOpen(false)}
        />
      )}
    </div>
  );
};

export default ManagerPage;
