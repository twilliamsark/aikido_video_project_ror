require "test_helper"

class AuthenticationFlowTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = Teacher.create!(
      email_address: "teacher@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  test "public root is available without authentication" do
    get root_path

    assert_response :success
    assert_select "h1", "Aikido Video Library"
  end

  test "teacher area requires authentication" do
    get teacher_root_path

    assert_redirected_to new_session_path
  end

  test "teacher can sign in" do
    get teacher_root_path

    post session_path, params: {
      email_address: @teacher.email_address,
      password: "password"
    }

    assert_redirected_to teacher_root_url
  end
end
