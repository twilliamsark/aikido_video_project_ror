module Videos
  class Query
    SORTS = {
      "newest" => { created_at: :desc },
      "oldest" => { created_at: :asc },
      "title_asc" => { title: :asc },
      "title_desc" => { title: :desc },
      "recently_updated" => { updated_at: :desc }
    }

    DEFAULT_SORT = "newest"

    def self.call(scope: Video.all, query: nil, sort: nil)
      new(scope:, query:, sort:).call
    end

    def initialize(scope:, query:, sort:)
      @scope = scope
      @query = query
      @sort = sort
    end

    def call
      apply_sort(apply_search(scope))
    end

    private
      attr_reader :scope, :query, :sort

      def apply_search(relation)
        search_terms.reduce(relation) do |current_scope, term|
          current_scope.where("search_text LIKE ?", "%#{sanitize_like(term)}%")
        end
      end

      def apply_sort(relation)
        relation.order(SORTS.fetch(sort.to_s, SORTS[DEFAULT_SORT]))
      end

      def search_terms
        query.to_s.strip.squish.downcase.split
      end

      def sanitize_like(term)
        ActiveRecord::Base.sanitize_sql_like(term)
      end
  end
end
