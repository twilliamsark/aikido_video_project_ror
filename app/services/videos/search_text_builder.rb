module Videos
  class SearchTextBuilder
    def self.call(video)
      new(video).call
    end

    def initialize(video)
      @video = video
    end

    def call
      [ title, keyword_names, description ].join(" ").squish.downcase
    end

    private
      attr_reader :video

      def title
        video.title.to_s
      end

      def keyword_names
        if video.association(:keywords).loaded? || video.persisted?
          video.keywords.map(&:name).join(" ")
        else
          ""
        end
      end

      def description
        video.description_plain_text.presence || video.description.to_plain_text
      end
  end
end
