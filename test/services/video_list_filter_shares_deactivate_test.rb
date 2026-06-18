require "test_helper"

class VideoListFilterSharesDeactivateTest < ActiveSupport::TestCase
  setup do
    @teacher = create_teacher
    @filter = @teacher.video_list_filters.create!(name: "Weapons", sort_key: "newest")
  end

  test "deactivates a share without destroying it" do
    share = VideoListFilterShares::Create.call(video_list_filter: @filter, teacher: @teacher)

    assert_no_difference -> { VideoListFilterShare.count } do
      VideoListFilterShares::Deactivate.call(video_list_filter: @filter)
    end

    assert_not share.reload.active?
    assert_predicate share.unshared_at, :present?
  end

  test "does nothing when no share exists" do
    assert_nil VideoListFilterShares::Deactivate.call(video_list_filter: @filter)
  end
end
