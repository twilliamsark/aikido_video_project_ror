class Keyword < ApplicationRecord
  has_many :video_keywords, dependent: :destroy
  has_many :videos, through: :video_keywords

  before_validation :set_normalized_name

  validates :name, presence: true
  validates :normalized_name, presence: true, uniqueness: true

  def self.normalize(name)
    name.to_s.strip.squish.downcase
  end

  private
    def set_normalized_name
      self.name = name.to_s.strip.squish
      self.normalized_name = self.class.normalize(name)
    end
end
