class SalmonController < ApplicationController
  def feeds
    SalmonInterpreter.new(
      request.body.read,
      {
        :feed_id  => params[:id],
        :root_url => root_url
      }
    ).interpret

    if Rails.env.development?
      puts "Salmon notification"
    end

    status 200
    return
  rescue MongoMapper::DocumentNotFound, ArgumentError, RstatUs::InvalidSalmonMessage
    render :file => "#{Rails.root}/public/404", :status => 404
    return
  end
end
