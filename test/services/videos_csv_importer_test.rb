require "test_helper"

class VideosCsvImporterTest < ActiveSupport::TestCase
  setup do
    @teacher = create_teacher
  end

  test "creates videos from case insensitive name and url headers" do
    csv = <<~CSV
      NAME,Url,keywords,notes
      Ikkyo Basics,https://youtu.be/aaaaaaaaaaa,Ukemi; Basics,Weapons; basics;
    CSV

    result = Videos::CsvImporter.call(io: StringIO.new(csv), teacher: @teacher)

    assert_equal({ created: 1, merged: 0, skipped: 0, errors: [] }, result)

    video = Video.find_by!(youtube_video_id: "aaaaaaaaaaa")
    assert_equal "Ikkyo Basics", video.title
    assert_equal @teacher, video.teacher
    assert_equal [ "basics", "ukemi", "weapons" ], video.keywords.map(&:normalized_name).sort
  end

  test "merges rows matched by youtube video id without changing existing fields" do
    Keyword.create!(name: "Ikkyo")
    video = @teacher.videos.create!(title: "Original Title", youtube_url: "https://youtu.be/bbbbbbbbbbb")
    Videos::KeywordAssigner.call(video:, names: "Ukemi")

    csv = <<~CSV
      name,url,keywords,extra
      Changed Title,https://www.youtube.com/watch?v=bbbbbbbbbbb,ikkyo; Weapons,
      Changed Again,https://www.youtube.com/shorts/bbbbbbbbbbb,Kokyu,
    CSV

    result = Videos::CsvImporter.call(io: StringIO.new(csv), teacher: @teacher)

    assert_equal({ created: 0, merged: 2, skipped: 0, errors: [] }, result)
    assert_equal "Original Title", video.reload.title
    assert_equal "https://youtu.be/bbbbbbbbbbb", video.youtube_url
    assert_equal [ "Ikkyo", "Kokyu", "Ukemi", "Weapons" ], video.keywords.order(:name).pluck(:name)
  end

  test "removes duplicate keywords from the final merged video keyword list" do
    video = @teacher.videos.create!(title: "Original Title", youtube_url: "https://youtu.be/hhhhhhhhhhh")
    Videos::KeywordAssigner.call(video:, names: "Ukemi, Ikkyo")

    csv = <<~CSV
      name,url,keywords,extra
      Import Title,https://www.youtube.com/watch?v=hhhhhhhhhhh,ukemi; UKEMI; Weapons,Ikkyo; weapons
    CSV

    result = Videos::CsvImporter.call(io: StringIO.new(csv), teacher: @teacher)

    assert_equal 1, result[:merged]
    assert_equal [ "Ikkyo", "Ukemi", "Weapons" ], video.keywords.order(:name).pluck(:name)
    assert_equal video.keywords.count, video.keywords.distinct.count
  end

  test "skips rows with missing names or unsupported youtube urls" do
    csv = <<~CSV
      name,url,keywords
      ,https://youtu.be/ccccccccccc,Ukemi
      Bad URL,https://example.com/watch?v=ccccccccccc,Ikkyo
    CSV

    result = Videos::CsvImporter.call(io: StringIO.new(csv), teacher: @teacher)

    assert_equal 0, result[:created]
    assert_equal 0, result[:merged]
    assert_equal 2, result[:skipped]
    assert_equal [ 2, 3 ], result[:errors].map { |error| error[:row] }
    assert_equal [ "Name is missing", "YouTube URL is missing or unsupported" ], result[:errors].map { |error| error[:reason] }
  end

  test "reports missing required headers" do
    result = Videos::CsvImporter.call(io: StringIO.new("title,link
Ikkyo,https://youtu.be/ddddddddddd
"), teacher: @teacher)

    assert_equal 0, result[:created]
    assert_equal 0, result[:merged]
    assert_equal 0, result[:skipped]
    assert_equal [ { row: 1, name: nil, reason: "Header row must contain name and url columns" } ], result[:errors]
  end
end
