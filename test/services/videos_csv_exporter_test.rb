require "test_helper"
require "csv"

class VideosCsvExporterTest < ActiveSupport::TestCase
  setup do
    @teacher = create_teacher
  end

  test "exports videos with standard csv quoting and alphabetized semicolon keywords" do
    video = @teacher.videos.create!(title: 'Ikkyo, "Basics"', youtube_url: "https://youtu.be/eeeeeeeeeee")
    Videos::KeywordAssigner.call(video:, names: "Weapons, Ukemi")

    output = Videos::CsvExporter.call(Video.all)

    assert_includes output, '"Ikkyo, ""Basics"""'

    rows = CSV.parse(output, headers: true)
    assert_equal [ "name", "url", "keywords" ], rows.headers
    assert_equal 'Ikkyo, "Basics"', rows.first["name"]
    assert_equal "https://youtu.be/eeeeeeeeeee", rows.first["url"]
    assert_equal "Ukemi;Weapons", rows.first["keywords"]
  end
end
