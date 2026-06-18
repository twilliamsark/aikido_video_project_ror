# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
teacher_email = ENV.fetch("SEED_TEACHER_EMAIL", "teacher@example.com")
teacher_password = ENV.fetch("SEED_TEACHER_PASSWORD", "password")

Teacher.find_or_create_by!(email_address: teacher_email) do |teacher|
  teacher.password = teacher_password
  teacher.password_confirmation = teacher_password
end
