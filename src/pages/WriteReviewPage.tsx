import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { Star, ImagePlus, X } from 'lucide-react';
import { CheckCircle } from 'lucide-react';

const RATING_MESSAGES = {
  1: 'Not Good',
  2: 'Could\'ve been better',
  3: 'OK',
  4: 'Good',
  5: 'Great'
};

interface StarButtonProps {
  selected: boolean;
  onClick: () => void;
  disabled: boolean;
}

const WriteReviewPage = () => {
  const { storeid } = useParams();
  const [comment, setComment] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [storeName, setStoreName] = useState('');
  const [rating, setRating] = useState<number>(1);
  const [selectedImages, setSelectedImages] = useState<string[]>([]);
  const [submitted, setSubmitted] = useState(false);

  const handleImageSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = event.target.files;
    if (!files) return;

    // Convert selected files to data URLs for preview
    Array.from(files).forEach(file => {
      const reader = new FileReader();
      reader.onloadend = () => {
        setSelectedImages(prev => [...prev, reader.result as string]);
      };
      reader.readAsDataURL(file);
    });
  };

  const removeImage = (index: number) => {
    setSelectedImages(prev => prev.filter((_, i) => i !== index));
  };

  const StarButton: React.FC<StarButtonProps> = ({ selected, onClick, disabled }) => (
    <button
      onClick={onClick}
      disabled={disabled}
      className="focus:outline-none"
    >
      <Star
        size={24}
        className={selected ? 'text-yellow-400 fill-current' : 'text-gray-300'}
      />
    </button>
  );

  useEffect(() => {
    const fetchStoreName = async () => {
      if (!storeid) {
        setError('Store ID is required');
        return;
      }

      try {
        const { data, error } = await supabase
          .from('store')
          .select('store_name')
          .eq('store_number', storeid)
          .single();

        if (error) throw error;
        if (data) {
          setStoreName(data.store_name);
          // Update page title
          document.title = 'Write Review';
        }
      } catch (err) {
        console.error('Error fetching store:', err);
        setError('Store not found');
      }
    };

    fetchStoreName();
    
    // Reset title when component unmounts
    return () => {
      document.title = 'Fast Checkin';
    };
  }, [storeid]);

  const handleSubmit = async () => {
    if (!rating) {
      setError('Please select a rating');
      return;
    }
    
    if (!comment.trim()) {
      setError('Please enter your review');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      const { error: submitError } = await supabase
        .from('reviews')
        .insert({
          phone_number: '+10000000000', // Anonymous review
          rating: rating,
          comment: comment.trim(),
          storeid: Number(storeid)
        });

      if (submitError) throw submitError;

      // Show success message
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
      <div className="min-h-screen w-screen bg-gray-100 flex items-center justify-center">
        <div className="w-full h-full md:h-auto md:w-[480px] p-6">
          <div>
            <p className="text-red-600 text-center">{error}</p>
          </div>
        </div>
      </div>
    );
  }

  if (submitted) {
    return (
      <div className="min-h-screen w-screen bg-gray-100 flex items-center justify-center">
        <div className="w-full h-full md:h-auto md:w-[480px] p-6">
          <div className="text-center">
            <CheckCircle className="mx-auto mb-4 text-green-500" size={48} />
            <h2 className="text-2xl font-bold text-gray-800 mb-2">Your review has been posted for review!</h2>
            <p className="text-gray-600 mb-6">Thank you for your feedback.</p>
            <button
              onClick={() => window.close()}
              className="px-6 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen w-full bg-gray-100 flex items-center justify-center p-4">
      <div className="w-full max-w-[480px] flex flex-col">
        <div>
          <h1 className="text-2xl font-bold text-gray-800 mb-6">
            {storeName.toUpperCase()}
          </h1>
          
          {error && <p className="text-red-500 text-sm mb-4">{error}</p>}

          <div className="mb-3">
            <div className="border-2 border-blue-500 rounded-lg p-4">
              <div className="flex items-center gap-2 mb-4">
                {[1, 2, 3, 4, 5].map((star) => (
                  <StarButton
                    key={star}
                    selected={star <= rating}
                    onClick={() => setRating(star)}
                    disabled={isSubmitting}
                  />
                ))}
                <span className="text-sm text-gray-600 ml-1">{RATING_MESSAGES[rating]}</span>
              </div>
              
              <p className="text-gray-600 text-sm mb-2 font-medium">A few things to consider in your review</p>
              <div className="flex gap-2 mb-3">
                <span className="bg-gray-200 text-gray-700 text-sm font-medium px-2 py-0.5 rounded">Service Requested</span>
                <span className="bg-gray-200 text-gray-700 text-sm font-medium px-2 py-0.5 rounded">Quality</span>
                <span className="bg-gray-200 text-gray-700 text-sm font-medium px-2 py-0.5 rounded">Vibe</span>
              </div>
              <textarea
                value={comment}
                onChange={(e) => setComment(e.target.value)}
                placeholder="Start your review..."
                className="w-full h-40 p-3 border-none focus:ring-0 focus:outline-none resize-none bg-gray-100 rounded-md"
                disabled={isSubmitting}
              />
            </div>
            <p className="text-sm text-gray-500 mt-2">Reviews need to be at least 85 characters.</p>
          </div>

          <div className="mt-4">
            <p className="text-gray-700 font-medium mb-2">Attach photos</p>
            <div 
              onClick={() => document.getElementById('photo-upload')?.click()}
              className="border-2 border-dashed border-gray-300 rounded-lg p-8 flex items-center justify-center cursor-pointer hover:border-gray-400 transition-colors"
            >
              <div className="flex flex-col items-center">
                <ImagePlus size={24} className="text-gray-400 mb-1" />
              </div>
            </div>
            <input
              type="file"
              id="photo-upload"
              className="hidden"
              accept="image/*"
              multiple
              onChange={handleImageSelect}
              disabled={isSubmitting}
            />
          </div>

          {selectedImages.length > 0 && (
            <div className="mt-4 grid grid-cols-2 md:grid-cols-3 gap-2">
              {selectedImages.map((image, index) => (
                <div key={index} className="relative aspect-square">
                  <img
                    src={image}
                    alt={`Preview ${index + 1}`}
                    className="w-full h-full object-cover rounded-lg"
                  />
                  <button
                    onClick={() => removeImage(index)}
                    className="absolute -top-1 -right-1 bg-red-500 text-white rounded-full p-1 hover:bg-red-600 shadow-md"
                  >
                    <X size={16} />
                  </button>
                </div>
              ))}
            </div>
          )}

          <button
            onClick={handleSubmit}
            disabled={isSubmitting || !comment.trim()}
            className="w-full md:w-48 mt-4 mb-4 bg-red-600 text-white py-3 rounded font-medium hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isSubmitting ? 'Posting...' : 'Post Review'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default WriteReviewPage;