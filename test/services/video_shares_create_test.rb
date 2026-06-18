require "test_helper"

class VideoSharesCreateTest < ActiveSupport::TestCase
  setup do
    @teacher = create_teacher
    @other_teacher = create_teacher
    @video = @teacher.videos.create!(title: "Ikkyo", youtube_url: "https://youtu.be/jjjjjjjjjjj")
  end

  test "creates an active share" do
    share = VideoShares::Create.call(video: @video, teacher: @teacher)

    assert_predicate share, :active?
    assert_equal @teacher, share.teacher
    assert_predicate share.token, :present?
    assert_predicate share.shared_at, :present?
    assert_nil share.unshared_at
  end

  test "reactivates an existing share and reuses its token" do
    share = VideoShares::Create.call(video: @video, teacher: @teacher)
    token = share.token
    VideoShares::Deactivate.call(video: @video)

    reactivated_share = VideoShares::Create.call(video: @video, teacher: @other_teacher)

    assert_equal share.id, reactivated_share.id
    assert_equal token, reactivated_share.token
    assert_predicate reactivated_share, :active?
    assert_equal @other_teacher, reactivated_share.teacher
    assert_nil reactivated_share.unshared_at
  end
end
