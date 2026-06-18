module Public
  class VideoListFilterSharesController < ApplicationController
    allow_unauthenticated_access

    def show
      share = VideoListFilterShare.includes(:video_list_filter).find_by!(token: params[:token], active: true)
      @video_list_filter = share.video_list_filter
      @sort_options = Public::VideosController::SORT_OPTIONS
      @sort = params[:sort].presence || @video_list_filter.sort_key
      matching_videos = Videos::Query.call(scope: Video.includes(:keywords), query: @video_list_filter.query, sort: @sort)
      @pagination = Videos::Pagination.call(relation: matching_videos, page: params[:page])
      @videos = @pagination.records
    end
  end
end
