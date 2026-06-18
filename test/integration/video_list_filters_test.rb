require "test_helper"

class VideoListFiltersTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = create_teacher
    @other_teacher = create_teacher
    @ikkyo = @teacher.videos.create!(title: "Ikkyo Basics", youtube_url: "https://youtu.be/rrrrrrrrrrr", description: "<p>Blend and enter.</p>")
    @ukemi = @teacher.videos.create!(title: "Ukemi Drills", youtube_url: "https://youtu.be/sssssssssss", description: "<p>Falling safely.</p>")
    @weapons = @teacher.videos.create!(title: "Weapons Work", youtube_url: "https://youtu.be/ttttttttttt", description: "<p>Jo basics.</p>")
    Videos::KeywordAssigner.call(video: @ikkyo, names: "Ikkyo, Basics")
    Videos::KeywordAssigner.call(video: @ukemi, names: "Ukemi")
    Videos::KeywordAssigner.call(video: @weapons, names: "Weapons, Basics")
  end

  test "teacher can create update and delete an owned list filter" do
    sign_in_as(@teacher)

    assert_difference -> { VideoListFilter.count }, 1 do
      post teacher_video_list_filters_path, params: {
        video_list_filter: {
          name: "Basics List",
          query: "basics",
          sort_key: "title_asc",
          description: "<p>Foundational work.</p>"
        }
      }
    end

    filter = VideoListFilter.last
    assert_redirected_to teacher_video_list_filter_path(filter)
    assert_equal @teacher, filter.teacher
    assert_equal "basics", filter.query
    assert_includes filter.reload.description_plain_text, "Foundational work."

    patch teacher_video_list_filter_path(filter), params: {
      video_list_filter: { name: "Updated Basics", query: "ikkyo", sort_key: "newest", description: "<p>Updated.</p>" }
    }

    assert_redirected_to teacher_video_list_filter_path(filter)
    assert_equal "Updated Basics", filter.reload.name
    assert_equal "ikkyo", filter.query

    assert_difference -> { VideoListFilter.count }, -1 do
      delete teacher_video_list_filter_path(filter)
    end

    assert_redirected_to teacher_video_list_filters_path
  end

  test "teacher cannot manage another teacher's list filter" do
    filter = @teacher.video_list_filters.create!(name: "Private", query: "basics", sort_key: "newest")
    sign_in_as(@other_teacher)

    get teacher_video_list_filter_path(filter)
    assert_response :not_found

    patch teacher_video_list_filter_path(filter), params: { video_list_filter: { name: "Nope" } }
    assert_response :not_found

    delete teacher_video_list_filter_path(filter)
    assert_response :not_found
  end

  test "deleting a list filter destroys its share record" do
    filter = @teacher.video_list_filters.create!(name: "Basics", query: "basics", sort_key: "title_asc")
    VideoListFilterShares::Create.call(video_list_filter: filter, teacher: @teacher)
    sign_in_as(@teacher)

    assert_difference -> { VideoListFilterShare.count }, -1 do
      delete teacher_video_list_filter_path(filter)
    end
  end

  test "teacher can share unshare and reshare an owned list filter with the same token" do
    filter = @teacher.video_list_filters.create!(name: "Basics", query: "basics", sort_key: "title_asc")
    sign_in_as(@teacher)

    assert_difference -> { VideoListFilterShare.count }, 1 do
      post teacher_video_list_filter_share_path(filter)
    end

    share = filter.reload.video_list_filter_share
    token = share.token
    assert_redirected_to teacher_video_list_filter_path(filter)
    assert_predicate share, :active?

    assert_no_difference -> { VideoListFilterShare.count } do
      delete teacher_video_list_filter_share_path(filter)
    end

    assert_not share.reload.active?

    assert_no_difference -> { VideoListFilterShare.count } do
      post teacher_video_list_filter_share_path(filter)
    end

    assert_equal token, share.reload.token
    assert_predicate share, :active?
  end

  test "teacher cannot share another teacher's list filter" do
    filter = @teacher.video_list_filters.create!(name: "Private", query: "basics", sort_key: "newest")
    sign_in_as(@other_teacher)

    post teacher_video_list_filter_share_path(filter)
    assert_response :not_found

    delete teacher_video_list_filter_share_path(filter)
    assert_response :not_found
  end

  test "guest cannot access teacher list filter management" do
    get teacher_video_list_filters_path
    assert_redirected_to new_session_path

    post teacher_video_list_filters_path
    assert_redirected_to new_session_path
  end

  private
    def sign_in_as(teacher)
      post session_path, params: { email_address: teacher.email_address, password: "password" }
    end
end
