require "test_helper"

class TeacherVideosTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = Teacher.create!(email_address: "teacher@example.com", password: "password", password_confirmation: "password")
    @other_teacher = Teacher.create!(email_address: "other@example.com", password: "password", password_confirmation: "password")
  end

  test "teacher can create a video with keywords and rich text" do
    sign_in_as(@teacher)

    assert_difference -> { Video.count }, 1 do
      post teacher_videos_path, params: {
        video: {
          title: "Ikkyo Basics",
          youtube_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
          keyword_names: "Ikkyo, Basics",
          description: "<p>Blend and enter.</p>"
        }
      }
    end

    video = Video.last
    assert_redirected_to teacher_video_path(video)
    assert_equal @teacher, video.teacher
    assert_equal "dQw4w9WgXcQ", video.youtube_video_id
    assert_equal [ "Basics", "Ikkyo" ], video.keywords.order(:name).pluck(:name)
    assert_includes video.reload.description_plain_text, "Blend and enter."
  end

  test "teacher can update a video created by another teacher" do
    video = @teacher.videos.create!(title: "Old Title", youtube_url: "https://youtu.be/dQw4w9WgXcQ")
    sign_in_as(@other_teacher)

    patch teacher_video_path(video), params: {
      video: {
        title: "Updated Title",
        youtube_url: "https://www.youtube.com/shorts/dQw4w9WgXcQ",
        keyword_names: "Ukemi",
        description: "<p>Updated notes.</p>"
      }
    }

    assert_redirected_to teacher_video_path(video)
    assert_equal "Updated Title", video.reload.title
    assert_equal [ "Ukemi" ], video.keywords.pluck(:name)
  end

  test "teacher can delete a video created by another teacher" do
    video = @teacher.videos.create!(title: "Delete Me", youtube_url: "https://youtu.be/dQw4w9WgXcQ")
    sign_in_as(@other_teacher)

    assert_difference -> { Video.count }, -1 do
      delete teacher_video_path(video)
    end

    assert_redirected_to teacher_videos_path
  end

  test "guest cannot access teacher video management" do
    get teacher_videos_path

    assert_redirected_to new_session_path
  end

  private
    def sign_in_as(teacher)
      post session_path, params: { email_address: teacher.email_address, password: "password" }
    end
end
