ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "securerandom"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    def create_teacher(email_address: nil, password: "password")
      Teacher.create!(
        email_address: email_address || "teacher-#{SecureRandom.hex(8)}@example.com",
        password: password,
        password_confirmation: password
      )
    end
  end
end
