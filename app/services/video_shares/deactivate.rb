module VideoShares
  class Deactivate
    def self.call(video:)
      new(video:).call
    end

    def initialize(video:)
      @video = video
    end

    def call
      return unless video.video_share

      video.video_share.update!(active: false, unshared_at: Time.current)
      video.video_share
    end

    private
      attr_reader :video
  end
end
