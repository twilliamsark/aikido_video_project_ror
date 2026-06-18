require "test_helper"

class VideosPaginationTest < ActiveSupport::TestCase
  setup do
    @teacher = create_teacher
    14.times do |index|
      @teacher.videos.create!(title: "Video #{index.to_s.rjust(2, '0')}", youtube_url: "https://youtu.be/#{format('%011d', index)}")
    end
  end

  test "returns the requested page of records" do
    relation = Video.order(:title)
    pagination = Videos::Pagination.call(relation:, page: 2, per_page: 5)

    assert_equal 2, pagination.page
    assert_equal 5, pagination.per_page
    assert_equal 14, pagination.total_count
    assert_equal 3, pagination.total_pages
    assert_equal 1, pagination.previous_page
    assert_equal 3, pagination.next_page
    assert_equal [ "Video 05", "Video 06", "Video 07", "Video 08", "Video 09" ], pagination.records.pluck(:title)
  end

  test "normalizes invalid page and caps per page" do
    pagination = Videos::Pagination.call(relation: Video.all, page: -3, per_page: 200)

    assert_equal 1, pagination.page
    assert_equal Videos::Pagination::MAX_PER_PAGE, pagination.per_page
  end
end
