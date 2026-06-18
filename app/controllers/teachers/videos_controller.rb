module Teachers
  class VideosController < ApplicationController
    before_action :set_video, only: %i[ show edit update destroy ]
    before_action :set_keyword_names, only: %i[ edit update ]

    def index
      @videos = Video.includes(:teacher, :keywords).order(created_at: :desc)
    end

    def show
      set_keyword_names
    end

    def new
      @video = Current.teacher.videos.build
    end

    def create
      @video = Current.teacher.videos.build

      if save_video
        redirect_to teacher_video_path(@video), notice: "Video was created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if save_video
        redirect_to teacher_video_path(@video), notice: "Video was updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @video.destroy
      redirect_to teacher_videos_path, notice: "Video was deleted.", status: :see_other
    end

    private
      def set_video
        @video = Video.find(params[:id])
      end

      def save_video
        attributes = video_params
        keyword_names = attributes.delete(:keyword_names)
        @video.assign_attributes(attributes)
        @video.keyword_names = keyword_names

        saved = false

        Video.transaction do
          unless @video.save
            raise ActiveRecord::Rollback
          end

          Videos::KeywordAssigner.call(video: @video, names: keyword_names)
          saved = true
        end

        saved
      end

      def set_keyword_names
        @video.keyword_names ||= @video.keywords.order(:name).pluck(:name).join(", ")
      end

      def video_params
        params.require(:video).permit(:title, :youtube_url, :description, :keyword_names)
      end
  end
end
