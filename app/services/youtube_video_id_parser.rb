require "uri"

class YoutubeVideoIdParser
  VIDEO_ID_PATTERN = /\A[A-Za-z0-9_-]{11}\z/

  def self.call(url)
    new(url).call
  end

  def initialize(url)
    @url = url.to_s.strip
  end

  def call
    uri = URI.parse(@url)
    return unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

    video_id = extract_video_id(uri)
    video_id if video_id&.match?(VIDEO_ID_PATTERN)
  rescue URI::InvalidURIError
    nil
  end

  private
    def extract_video_id(uri)
      host = uri.host.to_s.downcase.delete_prefix("www.").delete_prefix("m.")
      path_segments = uri.path.to_s.split("/").reject(&:blank?)

      case host
      when "youtube.com"
        youtube_video_id(path_segments, uri)
      when "youtu.be"
        path_segments.first
      end
    end

    def youtube_video_id(path_segments, uri)
      case path_segments.first
      when "watch"
        Rack::Utils.parse_nested_query(uri.query)["v"]
      when "embed", "shorts"
        path_segments.second
      end
    end
end
