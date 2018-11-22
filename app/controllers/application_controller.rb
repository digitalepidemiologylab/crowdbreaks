class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?
  helper_method :current_or_guest_user

  # Dealing with guest user
  # ---------
  # if user is logged in, return current_user, else return guest_user
  def current_or_guest_user
    if current_user
      if session[:guest_user_id] && session[:guest_user_id] != current_user.id
        logging_in
        # reload guest_user to prevent caching problems before destruction
        guest_user(with_retry = false).try(:reload).try(:destroy)
        session[:guest_user_id] = nil
      end
      current_user
    else
      guest_user
    end
  end

  # find guest_user object associated with the current session,
  # creating one as needed
  def guest_user(with_retry = true)
    Rails.logger.debug "Checking whether guest user is present..."
    # Cache the value the first time it's gotten.
    @cached_guest_user ||= User.find(session[:guest_user_id] ||= create_guest_user.id)
  rescue ActiveRecord::RecordNotFound # if session[:guest_user_id] invalid
    Rails.logger.debug "Record not found"
    guest_user if with_retry
  end

  rescue_from CanCan::AccessDenied do |exception|
    flash[:danger] = "Access denied"
    redirect_to root_url
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end

  private

  # called (once) when the user logs in, insert any code your application needs
  # to hand off from guest_user to current_user.
  def logging_in
    # Change all results that were previously added by guest user to its new user id
    guest_results = guest_user.results.all
    guest_results.each do |r|
      r.user_id = current_user.id
      r.save!
    end
  end

  def create_guest_user
    Rails.logger.debug "Creating new guest user..."
    unique_id = "#{Time.current.to_i}#{rand(100)}"
    u = User.create(:username => "guest", :email => "guest_#{unique_id}@example.com")
    u.skip_confirmation!
    u.skip_notifications!
    u.save!(:validate => false)
    session[:guest_user_id] = u.id
    u
  end

  def set_locale
    if user_signed_in?
      if params[:locale].present? and Crowdbreaks::Locales.include?(params[:locale])
        I18n.locale = params[:locale]
        current_user.update_attribute(:locale, I18n.locale)
      else
        I18n.locale = current_user.locale.to_sym ||  I18n.default_locale
      end
    else
      I18n.locale = params[:locale] || I18n.default_locale
    end
  end

  def default_url_options(options = {})
    { locale: I18n.locale }.merge options 
  end
end
