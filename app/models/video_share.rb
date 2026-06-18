class VideoShare < ApplicationRecord
  belongs_to :teacher
  belongs_to :video

  before_validation :ensure_token

  validates :token, presence: true, uniqueness: true
  validates :video_id, uniqueness: true
  validates :active, inclusion: { in: [ true, false ] }

  private
    def ensure_token
      self.token ||= SecureRandom.urlsafe_base64(24)
    end
end
