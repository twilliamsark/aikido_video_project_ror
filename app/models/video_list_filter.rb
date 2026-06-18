class VideoListFilter < ApplicationRecord
  belongs_to :teacher
  has_one :video_list_filter_share, dependent: :destroy
  has_one :active_video_list_filter_share, -> { where(active: true) }, class_name: "VideoListFilterShare"
  has_rich_text :description

  before_validation :normalize_query
  before_save :set_description_plain_text

  validates :name, presence: true, length: { maximum: 160 }
  validates :sort_key, presence: true, inclusion: { in: Videos::Query::SORTS.keys }

  private
    def normalize_query
      self.query = query.to_s.strip.squish
    end

    def set_description_plain_text
      self.description_plain_text = description.to_plain_text
    end
end
