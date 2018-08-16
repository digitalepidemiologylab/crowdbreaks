module Manage
  class BaseController < ApplicationController

    private

    def current_ability
      @current_ability ||= ManageAbility.new(current_user)
    end
  end
end
