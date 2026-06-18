require "test_helper"

class VideosQueryTest < ActiveSupport::TestCase
  setup do
    @teacher = create_teacher
    @ikkyo = @teacher.videos.create!(title: "Ikkyo Basics", youtube_url: "https://youtu.be/mmmmmmmmmmm", description: "<p>Opening movement</p>")
    @ukemi = @teacher.videos.create!(title: "Ukemi Drills", youtube_url: "https://youtu.be/nnnnnnnnnnn", description: "<p>Falling practice</p>")
    @weapons = @teacher.videos.create!(title: "Weapons Work", youtube_url: "https://youtu.be/ooooooooooo", description: "<p>Jo and bokken basics</p>")

    Videos::KeywordAssigner.call(video: @ikkyo, names: "Basics, Tai sabaki")
    Videos::KeywordAssigner.call(video: @ukemi, names: "Ukemi")
    Videos::KeywordAssigner.call(video: @weapons, names: "Weapons")
  end

  test "search matches title keywords and description plain text" do
    assert_equal [ @ikkyo ], Videos::Query.call(query: "ikkyo").to_a
    assert_equal [ @ikkyo ], Videos::Query.call(query: "tai").to_a
    assert_equal [ @weapons ], Videos::Query.call(query: "bokken").to_a
  end

  test "multi word search requires all terms" do
    assert_equal [ @ikkyo ], Videos::Query.call(query: "basics tai").to_a
    assert_equal [], Videos::Query.call(query: "basics falling").to_a
  end

  test "sorts by supported options and falls back to newest" do
    assert_equal [ "Ikkyo Basics", "Ukemi Drills", "Weapons Work" ], Videos::Query.call(sort: "title_asc").pluck(:title)
    assert_equal [ "Weapons Work", "Ukemi Drills", "Ikkyo Basics" ], Videos::Query.call(sort: "title_desc").pluck(:title)
    assert_equal [ @weapons.id, @ukemi.id, @ikkyo.id ], Videos::Query.call(sort: "invalid").pluck(:id)
  end
end
