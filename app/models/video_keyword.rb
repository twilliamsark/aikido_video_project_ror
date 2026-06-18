class VideoKeyword < ApplicationRecord
  belongs_to :video
  belongs_to :keyword

  validates :keyword_id, uniqueness: { scope: :video_id }
end
