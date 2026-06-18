module VideoShares
  class Create
    def self.call(video:, teacher:)
      new(video:, teacher:).call
    end

    def initialize(video:, teacher:)
      @video = video
      @teacher = teacher
    end

    def call
      share = video.video_share || video.build_video_share
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
      attr_reader :video, :teacher
  end
end
