# This class handles sending emails. Everything related to it should go in
# here, that way it's just as easy as
# `Notifier.send_message_notification(me, you)` to send a message.
class Notifier 

  #this isn't used anymore, but I'm keeping it around so that it's easy to 
  #write the new confirmation code that will happen soon.
  def self.send_signup_notification(recipient, token)
    Pony.mail(:to => recipient, 
              :subject => "Thanks for signing up for rstat.us!",
              :from => "steve+rstatus@steveklabnik.com",
              :body => render_haml_template("signup", {:token => token}),
              :via => :smtp, :via_options => Rstatus::PONY_VIA_OPTIONS)
  end
  
  def self.send_forgot_password_notification(recipient, token)
    Pony.mail(:to => recipient, 
              :subject => "Reset your rstat.us password",
              :from => "steve+rstatus@steveklabnik.com",
              :body => render_haml_template("forgot_password", {:token => token}),
              :via => :smtp, :via_options => Rstatus::PONY_VIA_OPTIONS)
  end

  private

  # This was kinda crazy to figure out. We have to make our own instantiation
  # of the Engine, and then set local variables. Crazy.
  def self.render_haml_template(template, opts)
    engine = Haml::Engine.new(File.open("views/notifier/#{template}.haml", "rb").read)
    engine.render(Object.new, opts)
  end
end
