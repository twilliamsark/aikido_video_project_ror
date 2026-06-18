require "test_helper"

class KeywordTest < ActiveSupport::TestCase
  test "normalizes names for comparison while preserving display name" do
    keyword = Keyword.create!(name: "  Basic   Ukemi  ")

    assert_equal "Basic Ukemi", keyword.name
    assert_equal "basic ukemi", keyword.normalized_name
  end

  test "requires unique normalized names" do
    Keyword.create!(name: "Ikkyo")
    duplicate = Keyword.new(name: "  ikkyo  ")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:normalized_name], "has already been taken"
  end
end
