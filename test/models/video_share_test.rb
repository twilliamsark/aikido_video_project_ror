require "test_helper"

class VideoShareTest < ActiveSupport::TestCase
  setup do
    @teacher = create_teacher
    @video = @teacher.videos.create!(title: "Ikkyo", youtube_url: "https://youtu.be/iiiiiiiiiii")
  end

  test "generates a token" do
    share = @video.create_video_share!(teacher: @teacher)

    assert_predicate share.token, :present?
  end

  test "requires one share per video" do
    @video.create_video_share!(teacher: @teacher)
    duplicate = VideoShare.new(video: @video, teacher: @teacher)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:video_id], "has already been taken"
  end
end
