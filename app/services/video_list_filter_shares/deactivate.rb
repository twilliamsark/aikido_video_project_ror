module VideoListFilterShares
  class Deactivate
    def self.call(video_list_filter:)
      new(video_list_filter:).call
    end

    def initialize(video_list_filter:)
      @video_list_filter = video_list_filter
    end

    def call
      return unless video_list_filter.video_list_filter_share

      video_list_filter.video_list_filter_share.update!(active: false, unshared_at: Time.current)
      video_list_filter.video_list_filter_share
    end

    private
      attr_reader :video_list_filter
  end
end
