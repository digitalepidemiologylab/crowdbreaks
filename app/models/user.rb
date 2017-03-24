class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :trackable, :validatable, :confirmable, :lockable

  private

  # def user_params
  #   params.require(:user).permit(:email, :password, :password_confirmation, :remember_me)
  # end
end
