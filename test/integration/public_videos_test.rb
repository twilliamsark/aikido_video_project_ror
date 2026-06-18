require "test_helper"

class PublicVideosTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = create_teacher
    @ikkyo = @teacher.videos.create!(title: "Ikkyo Basics", youtube_url: "https://youtu.be/ppppppppppp", description: "<p>Blend and enter.</p>")
    @ukemi = @teacher.videos.create!(title: "Ukemi Drills", youtube_url: "https://youtu.be/qqqqqqqqqqq", description: "<h1>Falling safely</h1><p>Mat practice.</p>")
    Videos::KeywordAssigner.call(video: @ikkyo, names: "Ikkyo, Basics")
    Videos::KeywordAssigner.call(video: @ukemi, names: "Ukemi")
  end

  test "guest can browse all videos from root" do
    get root_path

    assert_response :success
    assert_select "h1", "Browse Videos"
    assert_select "article", 2
    assert_select "a", "Ikkyo Basics"
    assert_select "a", "Ukemi Drills"
  end

  test "guest can search videos by title keyword or description" do
    get videos_path(q: "blend")

    assert_response :success
    assert_select "article", 1
    assert_select "h2", /Ikkyo Basics/
    assert_select "h2", { text: /Ukemi Drills/, count: 0 }

    get videos_path(q: "ukemi")
    assert_select "article", 1
    assert_select "h2", /Ukemi Drills/
  end

  test "guest can sort videos" do
    get videos_path(sort: "title_asc")

    assert_response :success
    assert_select "article h2 a" do |links|
      assert_equal [ "Ikkyo Basics", "Ukemi Drills" ], links.map(&:text)
    end
  end

  test "public browse includes videos regardless of share status" do
    share = VideoShares::Create.call(video: @ikkyo, teacher: @teacher)
    VideoShares::Deactivate.call(video: @ikkyo)

    get videos_path

    assert_response :success
    assert_not share.reload.active?
    assert_select "h2", /Ikkyo Basics/
    assert_select "h2", /Ukemi Drills/
  end

  test "public index uses plain text description previews" do
    get videos_path(q: "falling")

    assert_response :success
    assert_select "article", text: /Falling safely Mat practice\./
    assert_no_match(/<h1>Falling safely<\/h1>/, response.body)
  end

  test "public browse paginates videos" do
    13.times do |index|
      @teacher.videos.create!(title: "Extra #{index.to_s.rjust(2, '0')}", youtube_url: "https://youtu.be/x#{format('%010d', index)}")
    end

    get videos_path(sort: "title_asc")

    assert_response :success
    assert_select "article", 12
    assert_select "nav[aria-label=?]", "Pagination"
    assert_select "a", "Next"

    get videos_path(sort: "title_asc", page: 2)

    assert_response :success
    assert_select "article", 3
    assert_select "a", "Previous"
  end

  test "guest can open a watch page from browse" do
    get video_path(@ikkyo)

    assert_response :success
    assert_select "h1", "Ikkyo Basics"
    assert_select "iframe[src=?][title=?][loading=?][referrerpolicy=?]", "https://www.youtube-nocookie.com/embed/ppppppppppp", "Ikkyo Basics video player", "lazy", "strict-origin-when-cross-origin"
    assert_select "iframe[allow=?]", "encrypted-media; picture-in-picture; web-share"
    assert_select ".prose", text: /Blend and enter/
  end
end
