module Doorkeeper
  class Doorkeeper::ApplicationsController < ::ApplicationController
    include Doorkeeper::Helpers::Controller
    respond_to :html

    before_filter :require_user
    before_filter :authenticate_admin!

    def index
      @applications = Application.all
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
      @application = Application.find(params[:id])
    end

    def edit
      @application = Application.find(params[:id])
    end

    def update
      @application = Application.find(params[:id])
      if @application.update_attributes(params[:application])
        flash[:notice] = I18n.t(:notice, :scope => [:doorkeeper, :flash, :applications, :update])
        respond_with [:oauth, @application]
      else
        render :edit
      end
    end

    def destroy
      @application = Application.find(params[:id])
      flash[:notice] = I18n.t(:notice, :scope => [:doorkeeper, :flash, :applications, :destroy]) if @application.destroy
      redirect_to oauth_applications_url
    end
  end
end
