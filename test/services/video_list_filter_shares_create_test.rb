require "test_helper"

class VideoListFilterSharesCreateTest < ActiveSupport::TestCase
  setup do
    @teacher = create_teacher
    @filter = @teacher.video_list_filters.create!(name: "Weapons", sort_key: "newest")
  end

  test "creates an active share" do
    share = VideoListFilterShares::Create.call(video_list_filter: @filter, teacher: @teacher)

    assert_predicate share, :active?
    assert_equal @teacher, share.teacher
    assert_predicate share.token, :present?
    assert_predicate share.shared_at, :present?
    assert_nil share.unshared_at
  end

  test "reactivates an existing share and reuses its token" do
    share = VideoListFilterShares::Create.call(video_list_filter: @filter, teacher: @teacher)
    token = share.token
    VideoListFilterShares::Deactivate.call(video_list_filter: @filter)

    reactivated_share = VideoListFilterShares::Create.call(video_list_filter: @filter, teacher: @teacher)

    assert_equal share.id, reactivated_share.id
    assert_equal token, reactivated_share.token
    assert_predicate reactivated_share, :active?
    assert_nil reactivated_share.unshared_at
  end
end
