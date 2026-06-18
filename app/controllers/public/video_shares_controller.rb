module Public
  class VideoSharesController < ApplicationController
    allow_unauthenticated_access

    def show
      share = VideoShare.includes(video: :keywords).find_by!(token: params[:token], active: true)
      @video = share.video

      render "public/videos/show"
    end
  end
end
