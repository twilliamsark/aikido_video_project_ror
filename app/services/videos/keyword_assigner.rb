module Videos
  class KeywordAssigner
    def self.call(video:, names:)
      new(video:, names:).call
    end

    def initialize(video:, names:)
      @video = video
      @names = names
    end

    def call
      keywords = normalized_names.map do |name|
        Keyword.find_or_create_by!(normalized_name: Keyword.normalize(name)) do |keyword|
          keyword.name = name
        end
      end

      video.keywords = keywords
      video.rebuild_search_text!
      keywords
    end

    private
      attr_reader :video, :names

      def normalized_names
        names.to_s.split(",").map { |name| name.strip.squish }.reject(&:blank?).uniq { |name| Keyword.normalize(name) }
      end
  end
end
