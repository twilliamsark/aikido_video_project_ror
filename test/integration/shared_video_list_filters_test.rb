require "test_helper"

class SharedVideoListFiltersTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = create_teacher
    @ikkyo = @teacher.videos.create!(title: "Ikkyo Basics", youtube_url: "https://youtu.be/uuuuuuuuuuu", description: "<p>Blend and enter.</p>")
    @ukemi = @teacher.videos.create!(title: "Ukemi Drills", youtube_url: "https://youtu.be/vvvvvvvvvvv", description: "<p>Falling safely.</p>")
    @weapons = @teacher.videos.create!(title: "Weapons Basics", youtube_url: "https://youtu.be/wwwwwwwwwww", description: "<p>Jo basics.</p>")
    Videos::KeywordAssigner.call(video: @ikkyo, names: "Ikkyo, Basics")
    Videos::KeywordAssigner.call(video: @ukemi, names: "Ukemi")
    Videos::KeywordAssigner.call(video: @weapons, names: "Weapons, Basics")
    @filter = @teacher.video_list_filters.create!(
      name: "Basics Collection",
      query: "basics",
      sort_key: "title_asc",
      description: "<h1>Start here</h1><p>Foundational videos.</p>"
    )
    @share = VideoListFilterShares::Create.call(video_list_filter: @filter, teacher: @teacher)
  end

  test "guest can open an active shared list filter" do
    get public_video_list_path(@share.token)

    assert_response :success
    assert_select "h1", "Basics Collection"
    assert_select ".prose", text: /Start here/
    assert_select "article h2 a" do |links|
      assert_equal [ "Ikkyo Basics", "Weapons Basics" ], links.map(&:text)
    end
    assert_select "h2", { text: /Ukemi Drills/, count: 0 }
  end

  test "guest can sort within a shared list without changing the saved filter" do
    get public_video_list_path(@share.token), params: { sort: "title_desc" }

    assert_response :success
    assert_select "article h2 a" do |links|
      assert_equal [ "Weapons Basics", "Ikkyo Basics" ], links.map(&:text)
    end
    assert_equal "title_asc", @filter.reload.sort_key
    assert_equal "basics", @filter.query
  end

  test "shared list includes matching videos regardless of video share status" do
    video_share = VideoShares::Create.call(video: @ikkyo, teacher: @teacher)
    VideoShares::Deactivate.call(video: @ikkyo)

    get public_video_list_path(@share.token)

    assert_response :success
    assert_not video_share.reload.active?
    assert_select "h2", /Ikkyo Basics/
    assert_select "h2", /Weapons Basics/
  end

  test "inactive and unknown shared list URLs return not found" do
    VideoListFilterShares::Deactivate.call(video_list_filter: @filter)

    get public_video_list_path(@share.token)
    assert_response :not_found

    get public_video_list_path("missing-token")
    assert_response :not_found
  end
end
