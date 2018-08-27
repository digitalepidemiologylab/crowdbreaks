module Admin
  class ResultsController < BaseController
    load_and_authorize_resource

    def show
    end

    def index
      @results = Result.order(created_at: :desc).page params[:page]
    end

    def destroy
      if @result.destroy
        redirect_to(admin_results_path, notice: "Result successfully destroyed.")
      else
        redirect_to(admin_results_path, alert: 'Something went wrong when destroying result.')
      end
    end
  end
end
