class PasswordsMailer < ApplicationMailer
  def reset(teacher)
    @teacher = teacher
    mail subject: "Reset your password", to: teacher.email_address
  end
end
