require "test_helper"

class VideosKeywordAssignerTest < ActiveSupport::TestCase
  setup do
    teacher = create_teacher
    @video = teacher.videos.create!(title: "Ukemi", youtube_url: "https://youtu.be/dQw4w9WgXcQ")
  end

  test "assigns comma separated keywords and removes duplicates" do
    Videos::KeywordAssigner.call(video: @video, names: "Ukemi,  basic ukemi, ukemi")

    assert_equal [ "basic ukemi", "ukemi" ], @video.keywords.reload.map(&:normalized_name).sort
  end

  test "rebuilds video search text after keyword assignment" do
    Videos::KeywordAssigner.call(video: @video, names: "Weapons")

    assert_includes @video.reload.search_text, "weapons"
  end
end
