module Admin
  class UsersController < BaseController
    load_and_authorize_resource

    def new
      @user = User.new
    end

    def index
      @users = User.where.not("email ~* ?", "@example.com").order(role: :desc).page params[:page]
    end

    def create
    end

    def edit
      @user = User.find(params[:id])
    end

    def update
      @user = User.find(params[:id])
      if @user.update_attributes(sanitized_user_params)
        redirect_to(admin_users_path, notice: 'User successfully updated')
      else
        render :edit and return
      end
    end

    def destroy
    end

    private

    def sanitized_user_params
      sanitized_params = user_params
      sanitized_params[:role] = sanitized_params[:role].to_i
      sanitized_params
    end

    def user_params
      params.require(:user).permit(:username, :email, :role)
    end
  end
end
