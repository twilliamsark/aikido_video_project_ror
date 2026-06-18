class VideoListFilterShare < ApplicationRecord
  belongs_to :teacher
  belongs_to :video_list_filter

  before_validation :ensure_token

  validates :token, presence: true, uniqueness: true
  validates :video_list_filter_id, uniqueness: true
  validates :active, inclusion: { in: [ true, false ] }

  private
    def ensure_token
      self.token ||= SecureRandom.urlsafe_base64(24)
    end
end
