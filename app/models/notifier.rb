# This class handles sending emails. Everything related to it should go in
# here, that way it's just as easy as
# `Notifier.send_message_notification(me, you)` to send a message.

class Notifier

  def self.send_forgot_password_notification(recipient, token)
    Pony.mail(:to => recipient,
              :subject => "Reset your rstat.us password",
              :from => "rstatus@rstat.us",
              :body => render_haml_template("forgot_password", {:token => token}),
              :via => :smtp)
  end

  def self.send_confirm_email_notification(recipient, token)
    Pony.mail(:to => recipient,
              :subject => "Confirm your rstat.us email",
              :from => "rstatus@rstat.us",
              :body => render_haml_template("email_change", {:token => token}),
              :via => :smtp)
  end

  private

  # This was kinda crazy to figure out. We have to make our own instantiation
  # of the Engine, and then set local variables. Crazy.
  def self.render_haml_template(template, opts)
    engine = Haml::Engine.new(File.open("app/views/notifier/#{template}.haml", "rb").read)
    engine.render(Object.new, opts)
  end
end
