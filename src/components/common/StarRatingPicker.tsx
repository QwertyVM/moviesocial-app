"use client";

import React, { useState } from 'react';
import { Star } from 'lucide-react';

interface StarRatingPickerProps {
  value: number; // 0.5 to 5.0
  onChange: (value: number) => void;
  size?: 'sm' | 'md' | 'lg';
  readOnly?: boolean;
}

export const StarRatingPicker: React.FC<StarRatingPickerProps> = ({
  value,
  onChange,
  size = 'md',
  readOnly = false,
}) => {
  const [hoverValue, setHoverValue] = useState<number | null>(null);

  const starSizes = {
    sm: 'w-4 h-4',
    md: 'w-6 h-6',
    lg: 'w-8 h-8',
  }[size];

  const displayValue = hoverValue !== null ? hoverValue : value;

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>, starIndex: number) => {
    if (readOnly) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const isHalf = x < rect.width / 2;
    setHoverValue(starIndex + (isHalf ? 0.5 : 1.0));
  };

  const handleClick = (starIndex: number, e: React.MouseEvent<HTMLDivElement>) => {
    if (readOnly) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const isHalf = x < rect.width / 2;
    onChange(starIndex + (isHalf ? 0.5 : 1.0));
  };

  return (
    <div className="flex items-center gap-1.5" onMouseLeave={() => !readOnly && setHoverValue(null)}>
      {[0, 1, 2, 3, 4].map((starIndex) => {
        const starFillLevel = Math.max(0, Math.min(1, displayValue - starIndex));
        return (
          <div
            key={starIndex}
            className={`relative cursor-pointer transition-transform ${readOnly ? 'cursor-default' : 'hover:scale-110'}`}
            onMouseMove={(e) => handleMouseMove(e, starIndex)}
            onClick={(e) => handleClick(starIndex, e)}
          >
            {/* Background empty star */}
            <Star className={`${starSizes} text-gray-700 transition-colors`} />

            {/* Filled overlay (supports half or full) */}
            {starFillLevel > 0 && (
              <div
                className="absolute top-0 left-0 overflow-hidden text-cinema-gold"
                style={{ width: `${starFillLevel * 100}%` }}
              >
                <Star className={`${starSizes} fill-cinema-gold text-cinema-gold`} />
              </div>
            )}
          </div>
        );
      })}
      <span className="ml-2 font-mono text-sm font-semibold text-cinema-gold">
        {displayValue.toFixed(1)} / 5.0
      </span>
    </div>
  );
};

