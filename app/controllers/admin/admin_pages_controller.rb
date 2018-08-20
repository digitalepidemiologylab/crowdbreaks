module Admin
  class AdminPagesController < BaseController
    def dashboard
      authorize! :view, :admin_dashboard 
    end
  end
end
