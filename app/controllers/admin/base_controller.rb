module Admin
  class BaseController < ApplicationController
    layout 'admin'

    private

    def current_ability
      @current_ability ||= AdminAbility.new(current_user)
    end
  end
end
