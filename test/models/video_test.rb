require "test_helper"

class VideoTest < ActiveSupport::TestCase
  setup do
    @teacher = Teacher.create!(email_address: "teacher@example.com", password: "password", password_confirmation: "password")
  end

  test "derives YouTube video id from URL" do
    video = @teacher.videos.create!(title: "Ikkyo", youtube_url: "https://youtu.be/dQw4w9WgXcQ")

    assert_equal "dQw4w9WgXcQ", video.youtube_video_id
  end

  test "rejects unsupported YouTube URLs" do
    video = @teacher.videos.build(title: "Ikkyo", youtube_url: "https://example.com/video")

    assert_not video.valid?
    assert_includes video.errors[:youtube_url], "must be a supported YouTube URL"
  end

  test "stores plain text description and searchable text" do
    video = @teacher.videos.create!(
      title: "Ikkyo Basics",
      youtube_url: "https://youtu.be/dQw4w9WgXcQ",
      description: "<h1>Opening movement</h1><p>Blend and enter.</p>"
    )

    assert_includes video.reload.description_plain_text, "Opening movement"
    assert_includes video.search_text, "ikkyo basics"
    assert_includes video.search_text, "blend and enter"
  end
end
