module Public
  class VideosController < ApplicationController
    allow_unauthenticated_access

    SORT_OPTIONS = [
      [ "Newest", "newest" ],
      [ "Oldest", "oldest" ],
      [ "Title A-Z", "title_asc" ],
      [ "Title Z-A", "title_desc" ],
      [ "Recently updated", "recently_updated" ]
    ]

    def index
      @query = params[:q].to_s.strip.squish
      @sort = params[:sort].presence || Videos::Query::DEFAULT_SORT
      @sort_options = SORT_OPTIONS
      @videos = Videos::Query.call(scope: Video.includes(:keywords), query: @query, sort: @sort)
    end

    def show
      @video = Video.includes(:keywords).find(params[:id])
    end
  end
end
