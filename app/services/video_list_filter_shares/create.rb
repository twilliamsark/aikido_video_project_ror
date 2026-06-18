module VideoListFilterShares
  class Create
    def self.call(video_list_filter:, teacher:)
      new(video_list_filter:, teacher:).call
    end

    def initialize(video_list_filter:, teacher:)
      @video_list_filter = video_list_filter
      @teacher = teacher
    end

    def call
      share = video_list_filter.video_list_filter_share || video_list_filter.build_video_list_filter_share
      share.assign_attributes(
        teacher: teacher,
        active: true,
        shared_at: Time.current,
        unshared_at: nil
      )
      share.save!
      share
    end

    private
      attr_reader :video_list_filter, :teacher
  end
end
