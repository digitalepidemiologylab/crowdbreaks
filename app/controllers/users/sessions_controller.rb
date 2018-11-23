class Users::SessionsController < Devise::SessionsController
  skip_before_action :set_locale, only: [:create]
  after_action :set_locale_user_sign_in, only: [:create]
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
  

  private

  def set_locale_user_sign_in
    I18n.locale = current_user.locale.to_sym ||  I18n.default_locale
  end
end
