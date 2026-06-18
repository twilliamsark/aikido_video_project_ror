module Teachers
  class VideoSharesController < ApplicationController
    before_action :set_video

    def create
      share = VideoShares::Create.call(video: @video, teacher: Current.teacher)

      redirect_to teacher_video_path(@video), notice: "Video share link is active: #{public_video_share_url(share.token)}"
    end

    def destroy
      VideoShares::Deactivate.call(video: @video)

      redirect_to teacher_video_path(@video), notice: "Video share link was disabled.", status: :see_other
    end

    private
      def set_video
        @video = Video.find(params[:video_id])
      end
  end
end
