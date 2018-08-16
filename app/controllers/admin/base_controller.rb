module Admin
  class BaseController < ApplicationController

    private

    def current_ability
      @current_ability ||= AdminAbility.new(current_user)
    end
  end
end
