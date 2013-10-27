class PasswordService

  attr_accessor :message

  def initialize(user, options={})
    @user             = user
    @password         = options[:password]
    @confirm_password = options[:password_confirm]
    @email            = options[:email]
    @message          = fetch_message
  end

  def invalid?
    password_missing? || password_mismatch? || email_missing?
  end

  def reset_password
    @user.password = @password
    @user.save
  end

  private

  def password_missing?
    @password.blank?
  end

  def password_mismatch?
    @password != @confirm_password
  end

  def email_missing?
    @user.email ||= @email
    @user.email.blank?
  end

  def fetch_message
    if password_missing?
      "Password must be present"
    elsif password_mismatch?
      "Passwords do not match"
    elsif email_missing?
      "Email must be provided"
    end
  end

end
