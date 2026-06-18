require "test_helper"

class VideoListFilterShareTest < ActiveSupport::TestCase
  setup do
    @teacher = create_teacher
    @filter = @teacher.video_list_filters.create!(name: "Weapons", sort_key: "newest")
  end

  test "generates a token" do
    share = @filter.create_video_list_filter_share!(teacher: @teacher)

    assert_predicate share.token, :present?
  end

  test "requires one share per list filter" do
    @filter.create_video_list_filter_share!(teacher: @teacher)
    duplicate = VideoListFilterShare.new(video_list_filter: @filter, teacher: @teacher)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:video_list_filter_id], "has already been taken"
  end
end
