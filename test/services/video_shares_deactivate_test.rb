require "test_helper"

class VideoSharesDeactivateTest < ActiveSupport::TestCase
  setup do
    @teacher = create_teacher
    @video = @teacher.videos.create!(title: "Ikkyo", youtube_url: "https://youtu.be/kkkkkkkkkkk")
  end

  test "deactivates a share without destroying it" do
    share = VideoShares::Create.call(video: @video, teacher: @teacher)

    assert_no_difference -> { VideoShare.count } do
      VideoShares::Deactivate.call(video: @video)
    end

    assert_not share.reload.active?
    assert_predicate share.unshared_at, :present?
  end

  test "does nothing when no share exists" do
    assert_nil VideoShares::Deactivate.call(video: @video)
  end
end
