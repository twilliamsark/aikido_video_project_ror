module Teachers
  class VideoListFilterSharesController < ApplicationController
    before_action :set_video_list_filter

    def create
      share = VideoListFilterShares::Create.call(video_list_filter: @video_list_filter, teacher: Current.teacher)

      redirect_to teacher_video_list_filter_path(@video_list_filter), notice: "List filter share link is active: #{public_video_list_url(share.token)}"
    end

    def destroy
      VideoListFilterShares::Deactivate.call(video_list_filter: @video_list_filter)

      redirect_to teacher_video_list_filter_path(@video_list_filter), notice: "List filter share link was disabled.", status: :see_other
    end

    private
      def set_video_list_filter
        @video_list_filter = Current.teacher.video_list_filters.find(params[:video_list_filter_id])
      end
  end
end
