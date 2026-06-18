class Video < ApplicationRecord
  attr_accessor :keyword_names

  belongs_to :teacher
  has_many :video_keywords, dependent: :destroy
  has_many :keywords, through: :video_keywords
  has_rich_text :description

  before_validation :assign_youtube_video_id
  before_save :set_description_plain_text
  before_save :set_search_text

  validates :title, presence: true, length: { maximum: 160 }
  validates :youtube_url, presence: true
  validates :youtube_video_id, presence: true
  validate :youtube_url_is_supported

  def rebuild_search_text!
    update_columns(
      description_plain_text: description.to_plain_text,
      search_text: Videos::SearchTextBuilder.call(self),
      updated_at: Time.current
    )
  end

  private
    def assign_youtube_video_id
      self.youtube_video_id = YoutubeVideoIdParser.call(youtube_url)
    end

    def youtube_url_is_supported
      return if youtube_url.blank? || youtube_video_id.present?

      errors.add(:youtube_url, "must be a supported YouTube URL")
    end

    def set_description_plain_text
      self.description_plain_text = description.to_plain_text
    end

    def set_search_text
      self.search_text = Videos::SearchTextBuilder.call(self)
    end
end
