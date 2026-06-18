require "csv"

module Videos
  class CsvImporter
    REQUIRED_HEADERS = %w[ name url ]

    def self.call(io:, teacher:)
      new(io:, teacher:).call
    end

    def initialize(io:, teacher:)
      @io = io
      @teacher = teacher
      @result = { created: 0, merged: 0, skipped: 0, errors: [] }
    end

    def call
      table = CSV.parse(read_csv, headers: true)
      headers = (table.headers || []).compact

      unless required_headers_present?(headers)
        add_error(row: 1, name: nil, reason: "Header row must contain name and url columns")
        return result
      end

      import_rows(table, headers)
      result
    rescue CSV::MalformedCSVError => error
      add_error(row: nil, name: nil, reason: "CSV could not be parsed: #{error.message}")
      result
    end

    private
      attr_reader :io, :teacher, :result

      def read_csv
        io.respond_to?(:read) ? io.read : io.to_s
      end

      def required_headers_present?(headers)
        normalized_headers = headers.map { |header| normalize_header(header) }

        REQUIRED_HEADERS.all? { |header| normalized_headers.include?(header) }
      end

      def import_rows(table, headers)
        name_header = header_named(headers, "name")
        url_header = header_named(headers, "url")
        keyword_headers = headers - [ name_header, url_header ]

        table.each.with_index(2) do |row, row_number|
          import_row(row:, row_number:, name_header:, url_header:, keyword_headers:)
        end
      end

      def import_row(row:, row_number:, name_header:, url_header:, keyword_headers:)
        name = row[name_header].to_s.strip
        youtube_url = row[url_header].to_s.strip
        incoming_keywords = keyword_names_from(row, keyword_headers)

        return skip(row: row_number, name:, reason: "Name is missing") if name.blank?

        youtube_video_id = YoutubeVideoIdParser.call(youtube_url)
        return skip(row: row_number, name:, reason: "YouTube URL is missing or unsupported") if youtube_video_id.blank?

        if video = Video.find_by(youtube_video_id:)
          merge_keywords(video, incoming_keywords)
          result[:merged] += 1
        else
          create_video(name:, youtube_url:, incoming_keywords:, row_number:)
        end
      end

      def create_video(name:, youtube_url:, incoming_keywords:, row_number:)
        video = teacher.videos.build(title: name, youtube_url:)

        if video.save
          Videos::KeywordAssigner.call(video:, names: incoming_keywords)
          result[:created] += 1
        else
          skip(row: row_number, name:, reason: video.errors.full_messages.to_sentence)
        end
      end

      def merge_keywords(video, incoming_keywords)
        keyword_names = (video.keywords.pluck(:name) + incoming_keywords).uniq { |name| Keyword.normalize(name) }

        Videos::KeywordAssigner.call(video:, names: keyword_names)
      end

      def keyword_names_from(row, keyword_headers)
        keyword_headers.flat_map do |header|
          row[header].to_s.split(";")
        end.map { |keyword| keyword.strip.squish }.reject(&:blank?)
      end

      def header_named(headers, name)
        headers.find { |header| normalize_header(header) == name }
      end

      def normalize_header(header)
        header.to_s.strip.downcase
      end

      def skip(row:, name:, reason:)
        result[:skipped] += 1
        add_error(row:, name:, reason:)
      end

      def add_error(row:, name:, reason:)
        result[:errors] << { row:, name:, reason: }
      end
  end
end
