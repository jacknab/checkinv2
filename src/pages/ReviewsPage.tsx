import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { Star, Trash2 } from 'lucide-react';

interface Review {
  id: string;
  phone_number: string;
  rating: number;
  comment: string;
  created_at: string;
}

const ReviewsPage = () => {
  const { storeid } = useParams();
  const [reviews, setReviews] = useState<Review[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchReviews = async () => {
      if (!storeid) {
        setError('Store ID is required');
        setIsLoading(false);
        return;
      }

      try {
        const { data, error } = await supabase
          .from('reviews')
          .select('*')
          .eq('storeid', storeid)
          .order('created_at', { ascending: false });

        if (error) throw error;

        setReviews(data || []);
      } catch (err) {
        console.error('Error fetching reviews:', err);
        setError('Failed to load reviews');
      } finally {
        setIsLoading(false);
      }
    };

    fetchReviews();
  }, [storeid]);

  const handleDelete = async (reviewId: string) => {
    try {
      const { error } = await supabase
        .from('reviews')
        .delete()
        .eq('id', reviewId);

      if (error) throw error;

      // Update local state
      setReviews(reviews.filter(review => review.id !== reviewId));
    } catch (err) {
      console.error('Error deleting review:', err);
      setError('Failed to delete review');
    }
  };

  const formatPhoneNumber = (phone: string) => {
    const cleaned = phone.replace(/\D/g, '').slice(-10);
    return `(${cleaned.slice(0, 3)}) ${cleaned.slice(3, 6)}-${cleaned.slice(6)}`;
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: '2-digit',
      year: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      hour12: true
    });
  };

  if (isLoading) {
    return (
      <div className="flex-1 bg-gray-100 p-6 overflow-auto">
        <div className="w-full">
          <div className="bg-white rounded-lg shadow p-6">
            <p className="text-center text-gray-500">Loading reviews...</p>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex-1 bg-gray-100 p-6 overflow-auto">
        <div className="w-full">
          <div className="bg-white rounded-lg shadow p-6">
            <p className="text-center text-red-500">{error}</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 bg-gray-100 p-6 overflow-auto">
      <div className="w-full">
        <div className="bg-white rounded-lg shadow">
          <div className="p-6 border-b border-gray-200 text-center">
            <h1 className="text-2xl md:text-3xl font-bold text-gray-900 mb-2">Review dashboard</h1>
            <p className="text-sm md:text-base text-gray-500">
              Only owner can see these bad reviews. Good reviews may appear on Google, Yelp or Facebook
            </p>
          </div>

          <div className="divide-y divide-gray-200">
            {reviews.length === 0 ? (
              <p className="p-6 text-center text-gray-500">No reviews found</p>
            ) : (
              reviews.map((review) => (
                <div key={review.id} className="p-6">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-2">
                      <span className="text-gray-600">{formatPhoneNumber(review.phone_number)}</span>
                      <span className="text-gray-400">•</span>
                      <span className="text-gray-500 text-sm">
                        {formatDate(review.created_at)}
                      </span>
                    </div>
                    <button
                      onClick={() => handleDelete(review.id)}
                      className="text-red-500 hover:text-red-700 transition-colors p-2"
                      title="Delete review"
                    >
                      <Trash2 size={28} className="md:w-8 md:h-8 w-6 h-6" />
                    </button>
                  </div>
                  <div className="mt-3 flex items-center">
                    {[...Array(5)].map((_, index) => (
                      <Star
                        key={index}
                        size={24}
                        className={index < review.rating ? 'text-yellow-400 fill-current' : 'text-gray-300'}
                      />
                    ))}
                  </div>
                  <p className="mt-3 text-gray-700 text-base md:text-lg">{review.comment}</p>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default ReviewsPage;