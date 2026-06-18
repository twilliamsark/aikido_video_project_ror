module Videos
  class Pagination
    DEFAULT_PAGE = 1
    DEFAULT_PER_PAGE = 12
    MAX_PER_PAGE = 48

    attr_reader :relation, :page, :per_page, :total_count

    def self.call(relation:, page: nil, per_page: nil)
      new(relation:, page:, per_page:)
    end

    def initialize(relation:, page:, per_page:)
      @relation = relation
      @page = normalize_page(page)
      @per_page = normalize_per_page(per_page)
      @total_count = relation.count
    end

    def records
      relation.limit(per_page).offset(offset)
    end

    def total_pages
      return 1 if total_count.zero?

      (total_count.to_f / per_page).ceil
    end

    def previous_page
      page - 1 if page > 1
    end

    def next_page
      page + 1 if page < total_pages
    end

    def offset
      (page - 1) * per_page
    end

    private
      def normalize_page(value)
        parsed = value.to_i
        parsed.positive? ? parsed : DEFAULT_PAGE
      end

      def normalize_per_page(value)
        parsed = value.to_i
        return DEFAULT_PER_PAGE unless parsed.positive?

        [ parsed, MAX_PER_PAGE ].min
      end
  end
end
