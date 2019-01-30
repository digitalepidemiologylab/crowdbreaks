module Admin
  class UsersController < BaseController
    load_and_authorize_resource param_method: :sanitized_user_params

    before_action :allow_without_password, only: [:update]

    def new
    end

    def show
    end

    def index
      search_user = params[:search_user]
      if search_user.present?
        @users = @users.where('username LIKE ? OR email LIKE ?', "%#{search_user}%", "%#{search_user}%")
      end
      @users = @users.exclude_guests.order(role: :desc, created_at: :desc).page params[:page]
    end

    def create
      # don't send email notifications from admin interface
      @user.skip_notifications!
      if @user.save
        @user.confirm if @user.mark_as_confirmed == '1'
        respond_to do |format|
          format.html { redirect_to(admin_users_path, notice: 'User successfully created')}
        end
      else
        respond_to do |format|
          format.html { render :new }
        end
      end
    end

    def edit
    end

    def update
      @user.skip_notifications!
      if sanitized_user_params[:mark_as_confirmed] == '1' and not @user.confirmed?
        if not @user.confirm
          render :edit and return
        end
      end
      if @user.update_attributes(sanitized_user_params)
        redirect_to(admin_users_path, notice: 'User successfully updated')
      else
        render :edit and return
      end
    end

    def destroy
      if @user.destroy
        redirect_to(admin_users_path, notice: 'User successfully destroyed.')
      else
        redirect_to(admin_users_path, alert: 'Something went wrong when destroying user')
      end
    end

    private

    def sanitized_user_params
      sanitized_params = user_params
      sanitized_params[:role] = sanitized_params[:role].to_i
      sanitized_params
    end

    def user_params
      params.require(:user).permit(:username, :email, :role, :password, :password_confirmation, :mark_as_confirmed)
    end

    def allow_without_password
      if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
        params[:user].delete(:password)
        params[:user].delete(:password_confirmation)
      end
    end
  end
end
