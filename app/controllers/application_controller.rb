class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :set_locale

  def authenticate_active_admin_user!
    authenticate_user!
    return if current_user.admin?
    flash[:alert] = "Unauthorized Access!"
    redirect_to root_path
  end

  private

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options(options = {})
    { locale: I18n.locale }.merge options 
  end
end
