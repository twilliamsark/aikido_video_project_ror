require "test_helper"

class VideoSharingTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = create_teacher
    @other_teacher = create_teacher
    @video = @teacher.videos.create!(
      title: "Ikkyo Basics",
      youtube_url: "https://youtu.be/lllllllllll",
      description: "<p>Blend and enter.</p>"
    )
    Videos::KeywordAssigner.call(video: @video, names: "Ikkyo, Basics")
  end

  test "teacher can share a video created by another teacher" do
    sign_in_as(@other_teacher)

    assert_difference -> { VideoShare.count }, 1 do
      post teacher_video_share_path(@video)
    end

    share = @video.reload.video_share
    assert_redirected_to teacher_video_path(@video)
    assert_predicate share, :active?
    assert_equal @other_teacher, share.teacher
  end

  test "teacher can unshare a video without deleting the share record" do
    share = VideoShares::Create.call(video: @video, teacher: @teacher)
    sign_in_as(@teacher)

    assert_no_difference -> { VideoShare.count } do
      delete teacher_video_share_path(@video)
    end

    assert_redirected_to teacher_video_path(@video)
    assert_not share.reload.active?
    assert_predicate share.unshared_at, :present?
  end

  test "re-sharing reuses the existing token" do
    share = VideoShares::Create.call(video: @video, teacher: @teacher)
    token = share.token
    VideoShares::Deactivate.call(video: @video)
    sign_in_as(@other_teacher)

    assert_no_difference -> { VideoShare.count } do
      post teacher_video_share_path(@video)
    end

    assert_equal token, share.reload.token
    assert_predicate share, :active?
    assert_equal @other_teacher, share.teacher
  end

  test "guest can watch through an active share URL" do
    share = VideoShares::Create.call(video: @video, teacher: @teacher)

    get public_video_share_path(share.token)

    assert_response :success
    assert_select "h1", "Ikkyo Basics"
    assert_select "iframe[src=?]", "https://www.youtube-nocookie.com/embed/lllllllllll"
    assert_select ".prose", text: /Blend and enter/
  end

  test "inactive and unknown share URLs return not found" do
    share = VideoShares::Create.call(video: @video, teacher: @teacher)
    VideoShares::Deactivate.call(video: @video)

    get public_video_share_path(share.token)
    assert_response :not_found

    get public_video_share_path("missing-token")
    assert_response :not_found
  end

  test "guest cannot access teacher share actions" do
    post teacher_video_share_path(@video)
    assert_redirected_to new_session_path

    delete teacher_video_share_path(@video)
    assert_redirected_to new_session_path
  end

  private
    def sign_in_as(teacher)
      post session_path, params: { email_address: teacher.email_address, password: "password" }
    end
end
