require "csv"

module Videos
  class CsvExporter
    HEADERS = %w[ name url keywords ]

    def self.call(scope = Video.all)
      new(scope).call
    end

    def initialize(scope)
      @scope = scope
    end

    def call
      CSV.generate(headers: true) do |csv|
        csv << HEADERS

        scope.includes(:keywords).order(:title, :id).each do |video|
          csv << [ video.title, video.youtube_url, keyword_names(video) ]
        end
      end
    end

    private
      attr_reader :scope

      def keyword_names(video)
        video.keywords.map(&:name).sort_by(&:downcase).join(";")
      end
  end
end
