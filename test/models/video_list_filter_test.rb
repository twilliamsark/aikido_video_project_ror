require "test_helper"

class VideoListFilterTest < ActiveSupport::TestCase
  setup do
    @teacher = create_teacher
  end

  test "requires name and supported sort key" do
    filter = @teacher.video_list_filters.build(sort_key: "not-real")

    assert_not filter.valid?
    assert_includes filter.errors[:name], "can't be blank"
    assert_includes filter.errors[:sort_key], "is not included in the list"
  end

  test "normalizes query and stores plain text description" do
    filter = @teacher.video_list_filters.create!(
      name: "Weapons",
      query: "  jo   basics  ",
      sort_key: "title_asc",
      description: "<h1>Weapons list</h1><p>Jo basics.</p>"
    )

    assert_equal "jo basics", filter.query
    assert_includes filter.reload.description_plain_text, "Weapons list"
    assert_includes filter.description_plain_text, "Jo basics."
  end
end
