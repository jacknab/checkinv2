import React, { useState, useEffect } from 'react';
import { Routes, Route } from 'react-router-dom';
import { Settings, Calendar, Gift, Cake } from 'lucide-react';
import { getStoreId, setStoreId, submitPhoneNumber, fetchActiveCheckins, checkoutCustomer } from './config';
import SetupPage from './pages/SetupPage';
import StoreRecords from './pages/manager/StoreRecords';
import { supabase } from './lib/supabase';
import MyReviewPage from './pages/MyReviewPage';
import WriteReviewPage from './pages/WriteReviewPage';
import ReviewsPage from './pages/ReviewsPage';

// Import manager page components
import ManagerPage from './pages/ManagerPage';
import './App.css';

type Screen = 'phone' | 'name' | 'birthday' | 'success';

interface CheckInResponse {
  message: string;
  points: number;
  isNewPoint: boolean;
}

interface CheckIn {
  id: string;
  first_name: string;
  checkin_time: string;
  promo: boolean;
  selected?: boolean;
}

const MONTHS = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
];

function App() {
  const [phoneNumber, setPhoneNumber] = useState('');
  const [firstName, setFirstName] = useState('');
  const [birthMonth, setBirthMonth] = useState('');
  const [showWaitlist, setShowWaitlist] = useState(false);
  const [checkInSuccess, setCheckInSuccess] = useState(false);
  const [apiMessage, setApiMessage] = useState('');
  const [currentScreen, setCurrentScreen] = useState<Screen>('phone');
  const [selectedName, setSelectedName] = useState<string | null>(null);
  const [points, setPoints] = useState<number>(0);
  const [isNewPoint, setIsNewPoint] = useState<boolean>(false);
  const [recentCheckins, setRecentCheckins] = useState<CheckIn[]>([]);
  const [showStoreConfig, setShowStoreConfig] = useState(false);
  const [storeUuid, setStoreUuid] = useState('');
  const [configError, setConfigError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [processingId, setProcessingId] = useState<string | null>(null);
  const [storeId, setStoreId] = useState<string>('');
  const [promoName, setPromoName] = useState<string | null>(null);
  const [promoTrigger, setPromoTrigger] = useState<number>(0);
  const [customerPoints, setCustomerPoints] = useState<number | null>(null);

  // Load and validate store UUID on mount
  useEffect(() => {
    const storedId = getStoreId();
    if (storedId) {
      setStoreId(storedId);
      setStoreUuid(storedId);
    }
  }, []);

  const handleStoreConfigSave = async () => {
    if (storeUuid.length > 0) {
      // Update local storage
      localStorage.setItem('nail_salon_store_id', storeUuid);
      // Update state
      setStoreId(storeUuid);
      setShowStoreConfig(false);
    }
  };

  // Fetch active check-ins from the database
  useEffect(() => {
    const loadCheckins = async () => {
      if (!getStoreId()) {
        return;
      }
      
      console.log('App: Loading active check-ins');
      try {
        const checkins = await fetchActiveCheckins();

        // Fetch store's promo configuration
        const { data: storeData, error: storeError } = await supabase
          .from('store')
          .select('promo_name, promo_trigger')
          .eq('store_number', Number(getStoreId()))
          .single();

        if (storeError) {
          console.error('Failed to fetch store promo:', storeError);
        } else if (storeData?.promo_name) {
          setPromoName(storeData.promo_name);
          setPromoTrigger(storeData.promo_trigger || 0);
        }
        
        // Process duplicate names
        const processedCheckins = checkins.reduce((acc: CheckIn[], curr) => {
          // Count how many times this name appears before this instance
          const duplicateCount = acc.filter(item => 
            item.first_name.replace(/\s[A-Z]$/, '') === curr.first_name
          ).length;
          
          // If this is a duplicate, add a letter suffix
          const processedName = duplicateCount > 0 
            ? `${curr.first_name} ${String.fromCharCode(65 + duplicateCount)}` 
            : curr.first_name;
          
          return [...acc, { ...curr, first_name: processedName }];
        }, []);
        
        console.log(`App: Loaded ${processedCheckins.length} check-ins`);
        setRecentCheckins(processedCheckins);
      } catch (error) {
        console.error('App: Failed to fetch check-ins:', error);
      }
    };

    if (showWaitlist) {
      loadCheckins();
      // Poll more frequently (every 5 seconds) to keep the list updated
      const interval = setInterval(loadCheckins, 5000);
      return () => clearInterval(interval);
    }
  }, [showWaitlist]);

  const handleNameSelect = (name: string) => {
    setSelectedName(name);
    // Only mark the exact name as selected
    const updatedCheckins = recentCheckins.map(checkin => {
      return {
        ...checkin,
        selected: checkin.first_name === name
      };
    });
    setRecentCheckins(updatedCheckins);
  };

const handleRemoveName = () => {
    if (selectedName) {
      const updatedCheckins = recentCheckins.filter(checkin => checkin.first_name !== selectedName);
      setRecentCheckins(updatedCheckins);
      setSelectedName(null);
      setShowWaitlist(false);
      setPhoneNumber('');
    }
  };

  const handleNoShow = async (checkinId: string) => {
    if (!getStoreId()) {
      setApiMessage('Valid store configuration required');
      setShowWaitlist(false);
      setTimeout(() => setApiMessage(''), 3000);
      return;
    }

    setProcessingId(checkinId);
    
    try {
      const { error } = await supabase
        .from('checkin_list')
        .update({
          status: 'no_show',
          checkout_time: new Date().toISOString()
        })
        .eq('id', checkinId);

      if (error) throw error;
      
      // Refresh the checkins list
      const checkins = await fetchActiveCheckins();
      const processedCheckins = checkins.reduce((acc: CheckIn[], curr) => {
        const duplicateCount = acc.filter(item => 
          item.first_name.replace(/\s[A-Z]$/, '') === curr.first_name
        ).length;
        
        const processedName = duplicateCount > 0 
          ? `${curr.first_name} ${String.fromCharCode(65 + duplicateCount)}` 
          : curr.first_name;
        
        return [...acc, { ...curr, first_name: processedName }];
      }, []);
      
      setRecentCheckins(processedCheckins);
      setApiMessage('Customer marked as no-show');
      setShowWaitlist(false);
      
      setTimeout(() => {
        setApiMessage('');
      }, 3000);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to update status';
      setApiMessage(errorMessage);
      setTimeout(() => {
        setApiMessage('');
      }, 3000);
    } finally {
      setProcessingId(null);
    }
  };

  const handleCheckout = async (checkinId: string) => {
    // Ensure we have a validated store ID
    if (!getStoreId()) {
      setApiMessage('Valid store configuration required');
      setShowWaitlist(false);
      setTimeout(() => setApiMessage(''), 3000);
      return;
    }

    setIsLoading(true);
    
    // Attempt to check out all selected records
    try {
      await checkoutCustomer(checkinId, 'STAFF');
      
      // Refresh the checkins list
      const checkins = await fetchActiveCheckins();
      
      // Process duplicate names
      const processedCheckins = checkins.reduce((acc: CheckIn[], curr) => {
        const duplicateCount = acc.filter(item => 
          item.first_name.replace(/\s[A-Z]$/, '') === curr.first_name
        ).length;
        
        const processedName = duplicateCount > 0 
          ? `${curr.first_name} ${String.fromCharCode(65 + duplicateCount)}` 
          : curr.first_name;
        
        return [...acc, { ...curr, first_name: processedName }];
      }, []);
      
      setRecentCheckins(processedCheckins);
      setApiMessage('Customer checked out successfully');
      setShowWaitlist(false);
      
      setTimeout(() => {
        setApiMessage('');
      }, 3000);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to checkout customer';
      setApiMessage(errorMessage);
      setTimeout(() => {
        setApiMessage('');
      }, 3000);
    } finally {
      setIsLoading(false);
    }
  };

  const formatPhoneNumber = (number: string) => {
    const cleaned = ('' + number).replace(/\D/g, '');
    const areaCode = cleaned.slice(0, 3);
    const nextThree = cleaned.slice(3, 6);
    const lastFour = cleaned.slice(6, 10);

    let formattedNumber = '';

    if (areaCode) {
      formattedNumber += `(${areaCode}`;
      if (areaCode.length === 3) {
        formattedNumber += ') ';
      }
    }

    if (nextThree) {
      formattedNumber += nextThree;
      if (nextThree.length === 3) {
        formattedNumber += '-';
      }
    }

    if (lastFour) {
      formattedNumber += lastFour;
    }

    return formattedNumber;
  };

  const handleNumberClick = (number: string) => {
    if (phoneNumber.length < 10) {
      setPhoneNumber(prev => prev + number);
    }
  };

  const handleClear = () => {
    if (showWaitlist) {
      setShowWaitlist(false);
      setCurrentScreen('phone');
      resetState();
    } else {
      setPhoneNumber('');
    }
  };

  const resetState = () => {
    setSelectedName(null);
    setPhoneNumber('');
    setApiMessage('');
  };

  const handleSubmit = async () => {
    // Check for valid store configuration
    if (!getStoreId()) {
      setApiMessage('Valid store configuration required');
      setTimeout(() => setApiMessage(''), 4000);
      return;
    }

    if (phoneNumber.length === 10) {
      setIsLoading(true);
      try {
        const data: CheckInResponse = await submitPhoneNumber({
          phoneNumber,
          firstName: null,
          birthMonth: null
        });

        if (data.message === 'Welcome back!') {
          // Existing user - show success immediately
          setApiMessage(data.message);
          setPoints(data.points);
          setIsNewPoint(data.isNewPoint);
          setCurrentScreen('success');
          setCheckInSuccess(true);
        } else if (data.message === 'new_user') {
          // New user - continue with name collection
          setCurrentScreen('name');
        } else {
          setApiMessage(data.message);
        }
      } catch (error) {
        const errorMessage = error instanceof Error 
          ? error.message 
          : 'Unable to connect to server. Please try again in a few moments.';
        
        setApiMessage(errorMessage);
        console.error('Check-in error:', errorMessage);
        
        setTimeout(() => setApiMessage(''), 5000);
      } finally {
        setIsLoading(false);
      }
    }
  };

  useEffect(() => {
    if (checkInSuccess) {
      const timer = setTimeout(() => {
        setShowWaitlist(false);
        setCurrentScreen('phone');
        setCheckInSuccess(false);
        setPhoneNumber('');
        setFirstName('');
        setBirthMonth('');
        setApiMessage('');
      }, 5000);
      return () => clearTimeout(timer);
    }
  }, [checkInSuccess]);

  const handleLetterClick = (letter: string) => {
    if (firstName.length < 10) {
      setFirstName(prev => prev + letter);
    }
  };

  const handleNameBackspace = () => {
    setFirstName(prev => prev.slice(0, -1));
  };

  const handleNameClear = () => {
    setFirstName('');
  };
  
  const handleNameSubmit = () => {
    if (firstName.length > 0) {
      setCurrentScreen('birthday');
    }
  };

  const handleBirthMonthSelect = (month: string) => {
    setBirthMonth(month);
  };

  const handleFinalSubmit = async () => {
    // Check for valid store configuration
    if (!getStoreId()) {
      setApiMessage('Valid store configuration required');
      setTimeout(() => setApiMessage(''), 4000);
      return;
    }

    setIsLoading(true);
    try {
      const data = await submitPhoneNumber({
        phoneNumber,
        firstName,
        birthMonth: birthMonth || null
      });

      setApiMessage(data.message || `Welcome, ${firstName}!`);
      setPoints(data.points);
      setIsNewPoint(data.isNewPoint);
      
      setCurrentScreen('success');
      setCheckInSuccess(true);
      setShowWaitlist(false);
    } catch (error) {
      const errorMessage = error instanceof Error 
        ? error.message 
        : 'Unable to connect to server. Please try again in a few moments.';
      
      setApiMessage(errorMessage);
      setTimeout(() => setApiMessage(''), 5000);
    } finally {
      setIsLoading(false);
    }
  };

  const letterRows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M', '⌫'],
    ['space']
  ];

  return (
      <Routes>
        <Route path="/manager/*" element={<ManagerPage />} />
        <Route path="/isAdmin/*" element={<SetupPage />} />
        <Route path="/reviews/:storeid" element={<ReviewsPage />} />
        <Route path="/write-review/:storeid" element={<WriteReviewPage />} />
        <Route path="/myreview/:storeid" element={<MyReviewPage />} />
        <Route path="/isAdmin/stores" element={<StoreRecords storeId={storeId} />} />
        <Route path="/" element={
    <div className="checkin-container">
      <div className="curved-background" />
      <div className="content-container">
        <div className="left-section">
          <div className="logo-container">
            <img 
              src="https://raw.githubusercontent.com/jacknab/scripts/main/logo-Photoroom-Photoroom.png" 
              alt="Fast Checkin Logo" 
              className="logo-image" 
            />
          </div>
          <button 
            className="waiting-list-button" 
            onClick={() => setShowWaitlist(true)}
            disabled={!getStoreId()}
          >
            WAITING LIST
          </button>
          <div className="consent-text">
  <label>
    <input type="checkbox" defaultChecked style={{ marginRight: '10px' }} />
    By entering your phone number, you give Fast Checkin written consent to contact
    you at the number entered to send you reminders and promotions. Consent is not
    required to check in or make a purchase. You also agree to the Terms and Conditions.
    <br />
    <br />
    Version: 1.00
  </label>
</div>
        </div>
        <div className="right-section">
          {currentScreen === 'success' ? (
            <div className="flex flex-col items-center justify-center w-full max-w-md mx-auto p-8">
              <div className="text-2xl text-white mb-8">{apiMessage}</div>
              <div className="relative w-48 h-48">
                <div className="absolute inset-0">
                  <svg className="w-full h-full" viewBox="0 0 100 100">
                    <circle
                      cx="50"
                      cy="50"
                      r="45"
                      fill="none"
                      stroke="#2d2d2d"
                      strokeWidth="10"
                    />
                    <circle
                      cx="50"
                      cy="50"
                      r="45"
                      fill="none"
                      stroke="#4338ca"
                      strokeWidth="10"
                      strokeDasharray="282.7"
                      strokeDashoffset={282.7 - ((points / 10) * 282.7)}
                      transform="rotate(-90 50 50)"
                    />
                  </svg>
                </div>
                <div className="absolute inset-0 flex flex-col items-center justify-center text-white">
                  <span className="text-5xl font-bold">{points}</span>
                  <span className="text-lg mt-2">POINTS</span>
                </div>
              </div>
              <div className="mt-8 text-center">
                {promoTrigger > 0 && points < promoTrigger && (
                  <div className="text-white text-lg">
                    Only <span className="text-2xl font-bold text-indigo-500">{(promoTrigger + 1) - points}</span> points away
                    <br />from receiving your next
                    <br /><span className="text-2xl font-bold text-red-500">{promoName || 'REWARD'}</span>
                  </div>
                )}
              </div>
            </div>
          ) : currentScreen === 'birthday' ? (
            <div className="keypad-container">
              <div className="birthday-container">
                <div className="birthday-header">
                  <p className="birthday-message">
                    Receive a birthday gift from us.
                  </p>
                </div>
                <div className="birthday-content">
                  <div className="month-grid">
                    {MONTHS.map((month) => (
                      <button
                        key={month}
                        className={`month-button ${birthMonth === month ? 'selected' : ''}`}
                        onClick={() => handleBirthMonthSelect(month)}
                        disabled={isLoading}
                      >
                        {month}
                      </button>
                    ))}
                  </div>
                  <button
                    className="month-submit"
                    onClick={handleFinalSubmit}
                    disabled={isLoading}
                  >
                    {isLoading ? 'Processing...' : 'Next'}
                  </button>
                </div>
              </div>
            </div>
          ) : currentScreen === 'name' ? (
            <div className="keypad-container">
              <div className="input-section">
                <div className="name-display">
                  {firstName || 'FIRST NAME'}
                </div>
                {apiMessage && <p className="api-message">{apiMessage}</p>}
              </div>
              <div className="letter-keyboard">
                {letterRows.map((row, rowIndex) => (
                  <div key={rowIndex} className="letter-row">
                    {row.map(letter => letter === 'space' ? (
                      <button
                        key="space"
                        className="keypad-button letter-button"
                        onClick={handleNameSubmit}
                        disabled={firstName.length === 0 || isLoading}
                      >
                        {isLoading ? 'Processing...' : 'Submit'}
                      </button>
                    ) : (
                      <button
                        key={letter}
                        className={`keypad-button letter-button ${
                          letter === '⌫' ? 'backspace' : ''
                        }`}
                        onClick={() => {
                          if (letter === '⌫') handleNameBackspace();
                          else handleLetterClick(letter);
                        }}
                        disabled={isLoading}
                      >
                        {letter}
                      </button>
                    ))}
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <div className="keypad-container">
              {showWaitlist && (
                <div className="waitlist-panel">
                  <h2>Recent Check-ins</h2>
                  {promoName && promoTrigger && customerPoints === promoTrigger && (
                    <div className="bg-red-600 text-white p-3 rounded-lg mb-4 text-center font-medium">
                      {promoName}
                    </div>
                  )}
                  <div className="waitlist">
                    {recentCheckins.length === 0 ? (
                      <p className="empty-waitlist">No active check-ins found</p>
                    ) : (
                      recentCheckins.map((checkin, index) => (
                        <div key={checkin.id} className="waitlist-item">
                          <button
                            className={`waitlist-name ${checkin.selected ? 'selected' : ''}`}
                            onClick={() => handleNameSelect(checkin.first_name)}
                            disabled={isLoading}
                          >
                {checkin.promo && promoName && (
                <div className="bg-yellow-500 text-black font-bold text-sm px-2 py-1 rounded mb-1 flex items-center">
                <Gift className="w-4 h-4 mr-1" />
                {promoName}
                </div>
)}
                            <span>{index + 1}. {checkin.first_name}</span>
                          </button>
                          <button
                            className="no-show-button"
                            onClick={() => handleNoShow(checkin.id)}
                            disabled={isLoading || processingId === checkin.id}
                          >
                            {processingId === checkin.id ? '...' : '×'}
                          </button>
                          <button
                            className="checkout-button"
                            onClick={() => handleCheckout(checkin.id)}
                            disabled={isLoading || processingId === checkin.id}
                          >
                            {isLoading ? '...' : '+'}
                          </button>
                        </div>
                      ))
                    )}
                  </div>
                </div>
              )}
              <div className="input-section">
                <div className="text-section">
                  <p>Enter your cell phone number</p>
                  <div className="phone-display">
                    {formatPhoneNumber(phoneNumber)}
                  </div>
                  {apiMessage && <p className="api-message">{apiMessage}</p>}
                  {!getStoreId() && !apiMessage && (
                    <p className="api-message">Please configure store ID</p>
                  )}
                </div>
                <div className="keypad">
                  <div className="keypad-grid">
                    {[1, 2, 3, 4, 5, 6, 7, 8, 9, 'C', 0].map((num) => (
                      <button
                        key={num}
                        className="keypad-button digit-button"
                        onClick={() => {
                          if (num === 'C') {
                            handleClear();
                          } else {
                            handleNumberClick(num.toString());
                          }
                        }}
                        disabled={isLoading}
                      >
                        {num}
                      </button>
                    ))}
                    <button
                      className={`keypad-button next-button ${phoneNumber.length === 10 ? '' : 'hidden'}`}
                      onClick={handleSubmit}
                      disabled={isLoading || phoneNumber.length !== 10 || !getStoreId()}
                    >
                      {isLoading ? 'Processing...' : 'Next'}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
      {!getStoreId() && (
        <div
          className="store-config-button"
          onClick={() => setShowStoreConfig(true)}
        >
          <Settings size={24} />
        </div>
      )}
      {showStoreConfig && !getStoreId() && (
        <div className="store-config-popup">
          <div className="store-config-header">
            <h3>Store Configuration</h3>
          </div>
          <label htmlFor="storeId">STORE ID</label>
          <div className="store-input-container">
            <input
              id="storeId"
              type="text"
              value={storeUuid}
              onChange={(e) => setStoreUuid(e.target.value)}
              maxLength={6}
              placeholder="Enter store ID"
            />
          </div>
          {configError && <div className="config-error">{configError}</div>}
          <div className="store-config-buttons">
            <button 
              onClick={handleStoreConfigSave}
              disabled={storeUuid.length === 0}
            >
              Save
            </button>
            <button 
              onClick={() => setShowStoreConfig(false)}
              className="cancel-button"
            >
              Close
            </button>
          </div>
        </div>
      )}
      </div>
        } />
      </Routes>
  );
}

export default App;