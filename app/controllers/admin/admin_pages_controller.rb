module Admin
  class AdminPagesController < BaseController
    def dashboard
      authorize! :view, :dashboard 
    end
  end
end
