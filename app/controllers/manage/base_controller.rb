module Manage
  class BaseController < ApplicationController

    private

    def current_ability
      @current_ability ||= ManageAbility.new(current_user)
    end

    def param_bool_val(param, default: false)
      param == 'true' ? true : default
    end
  end
end
