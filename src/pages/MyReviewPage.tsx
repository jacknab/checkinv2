import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { SmilePlus, Meh, Frown } from 'lucide-react';

const MyReviewPage = () => {
  const { storeid } = useParams();
  const [storeName, setStoreName] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [reviewUrl, setReviewUrl] = useState('');
  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchStoreName = async () => {
      if (!storeid) {
        setError('Store ID is required');
        return;
      }

      try {
        const { data, error } = await supabase
          .from('store')
          .select('store_name, review_link')
          .eq('store_number', storeid)
          .single();

        if (error) throw error;
        if (data) {
          setStoreName(data.store_name);
          setReviewUrl(data.review_link || '');
        }
      } catch (err) {
        console.error('Error fetching store:', err);
        setError('Store not found');
      }
    };

    fetchStoreName();
  }, [storeid]);

  const handleRating = async (rating: number) => {
    if (!storeid) {
      setError('Store ID is required');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    // For "Great" or "Just OK" ratings, redirect to review URL if available
    if (rating === 1 || rating === 2) {
      window.location.href = `https://review.poolets.com/${storeid}`;
      return;
    } else if (rating === 3) {
      window.location.href = `/write-review/${storeid}`;
      return;
    }

    try {
      setSubmitted(true);
    } catch (err) {
      console.error('Error submitting review:', err);
      setError('Failed to submit review. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (error) {
    return (
      <div className="h-screen w-screen bg-gray-100 flex items-center justify-center">
        <div className="w-full h-full md:h-auto md:w-[480px] bg-white md:rounded-lg md:shadow-lg p-6 text-center flex flex-col items-center justify-center">
          <p className="text-red-600">{error}</p>
        </div>
      </div>
    );
  }

  if (submitted) {
    return (
      <div className="h-screen w-screen bg-gray-100 flex items-center justify-center">
        <div className="w-full h-full md:h-auto md:w-[480px] bg-white md:rounded-lg md:shadow-lg p-6 text-center flex flex-col items-center justify-center">
          <h2 className="text-2xl font-bold text-gray-800 mb-4">Thank You!</h2>
          <p className="text-gray-600">Your feedback has been submitted.</p>
          <button
            onClick={() => window.close()}
            className="mt-8 px-6 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
          >
            Close
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="h-screen w-screen bg-gray-100 flex items-center justify-center">
      <div className="w-full h-full md:h-auto md:w-[480px] bg-white md:rounded-lg md:shadow-lg p-6 flex flex-col justify-start">
        <h1 className="text-xl font-bold text-gray-800 text-center mb-6">
          <span className="text-left block">{storeName.toUpperCase()}</span>
        </h1>
        
        <p className="text-gray-600 text-left mb-6 text-lg">
          How would you rate the service you received?
        </p>

        <div className="space-y-4 mt-4">
          <button
            onClick={() => handleRating(1)}
            disabled={isSubmitting}
            className="w-full flex items-center justify-between px-6 py-4 bg-white border-2 border-gray-200 rounded-xl disabled:opacity-50 transition-all"
          >
            <span className="text-xl font-medium">Great</span>
            <SmilePlus className="text-green-500" size={24} />
          </button>

          <button
            onClick={() => handleRating(2)}
            disabled={isSubmitting}
            className="w-full flex items-center justify-between px-6 py-4 bg-white border-2 border-gray-200 rounded-xl disabled:opacity-50 transition-all"
          >
            <span className="text-xl font-medium">Just OK</span>
            <Meh className="text-yellow-500" size={24} />
          </button>

          <button
            onClick={() => handleRating(3)}
            disabled={isSubmitting}
            className="w-full flex items-center justify-between px-6 py-4 bg-white border-2 border-gray-200 rounded-xl disabled:opacity-50 transition-all"
          >
            <span className="text-xl font-medium">Bad</span>
            <Frown className="text-red-500" size={24} />
          </button>
        </div>
      </div>
    </div>
  );
};

export default MyReviewPage;