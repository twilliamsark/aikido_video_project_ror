require "test_helper"

class YoutubeVideoIdParserTest < ActiveSupport::TestCase
  test "extracts video id from supported YouTube URLs" do
    assert_equal "dQw4w9WgXcQ", YoutubeVideoIdParser.call("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    assert_equal "dQw4w9WgXcQ", YoutubeVideoIdParser.call("https://youtu.be/dQw4w9WgXcQ")
    assert_equal "dQw4w9WgXcQ", YoutubeVideoIdParser.call("https://www.youtube.com/embed/dQw4w9WgXcQ")
    assert_equal "dQw4w9WgXcQ", YoutubeVideoIdParser.call("https://www.youtube.com/shorts/dQw4w9WgXcQ")
  end

  test "rejects unsupported URLs" do
    assert_nil YoutubeVideoIdParser.call("https://example.com/watch?v=dQw4w9WgXcQ")
    assert_nil YoutubeVideoIdParser.call("not a url")
    assert_nil YoutubeVideoIdParser.call("https://www.youtube.com/watch?v=too-short")
  end
end
