module Manage
  class BaseController < ApplicationController
    before_action :authorize_admin

    private

    def authorize_admin
      raise CanCan::AccessDenied unless current_or_guest_user.admin?
    end
  end
end
