module Doorkeeper
  class Doorkeeper::ApplicationsController < ::ApplicationController
    include Doorkeeper::Helpers::Controller
    respond_to :html

    before_filter :require_user
    before_filter :authenticate_admin!
    before_filter :find_application, :only => [:show, :edit, :update, :destroy]

    def index
      @applications = Application.where(:owner_id => current_user.id)
    end

    def new
      @application = Application.new
    end

    def create
      @application = Application.new(
        :name => params[:application][:name],
        :redirect_uri => params[:application][:redirect_uri]
      )
      @application.owner = current_user
      if @application.save
        flash[:notice] = I18n.t(:notice, :scope => [:doorkeeper, :flash, :applications, :create])
        respond_with [:oauth, @application]
      else
        render :new
      end
    end

    def show
    end

    def edit
    end

    def update
      if @application.update_attributes(params[:application])
        flash[:notice] = I18n.t(:notice, :scope => [:doorkeeper, :flash, :applications, :update])
        respond_with [:oauth, @application]
      else
        render :edit
      end
    end

    def destroy
      flash[:notice] = I18n.t(:notice, :scope => [:doorkeeper, :flash, :applications, :destroy]) if @application.destroy
      redirect_to oauth_applications_url
    end

    private

    def find_application
      @application = Application.first(:id => params[:id], :owner_id => current_user.id)
      if @application.nil?
        render :file => "#{::Rails.root}/public/404", :status => 404
        return
      end
    end
  end
end
