module Public
  class VideosController < ApplicationController
    allow_unauthenticated_access

    def show
      @video = Video.includes(:keywords).find(params[:id])
    end
  end
end
