class Rstatus::Session < Rack::Session::Cookie
  def call(env)
    load_session(env)
    env["rack.session.options"][:expire_after] = (env['rack.session'][:remember_me] ? 30.days : 4.hours) if env['rack.session'][:user_id]
    status, headers, body = @app.call(env)
    commit_session(env, status, headers, body)
  end
end
