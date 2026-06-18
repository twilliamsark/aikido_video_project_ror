class Teacher < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :videos, dependent: :destroy
  has_many :video_shares, dependent: :destroy

  normalizes :email_address, with: ->(email) { email.strip.downcase }
end
