module Teachers
  class VideoListFiltersController < ApplicationController
    before_action :set_video_list_filter, only: %i[ show edit update destroy ]

    SORT_OPTIONS = Public::VideosController::SORT_OPTIONS

    def index
      @video_list_filters = Current.teacher.video_list_filters.includes(:active_video_list_filter_share).order(updated_at: :desc)
    end

    def show
    end

    def new
      @video_list_filter = Current.teacher.video_list_filters.build(sort_key: Videos::Query::DEFAULT_SORT)
    end

    def create
      @video_list_filter = Current.teacher.video_list_filters.build(video_list_filter_params)

      if @video_list_filter.save
        redirect_to teacher_video_list_filter_path(@video_list_filter), notice: "List filter was created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @video_list_filter.update(video_list_filter_params)
        redirect_to teacher_video_list_filter_path(@video_list_filter), notice: "List filter was updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @video_list_filter.destroy
      redirect_to teacher_video_list_filters_path, notice: "List filter was deleted.", status: :see_other
    end

    private
      def set_video_list_filter
        @video_list_filter = Current.teacher.video_list_filters.find(params[:id])
      end

      def video_list_filter_params
        params.require(:video_list_filter).permit(:name, :query, :sort_key, :description)
      end
  end
end
