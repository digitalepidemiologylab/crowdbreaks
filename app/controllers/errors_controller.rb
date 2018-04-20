class ErrorsController < ApplicationController
  layout 'error'
  skip_before_action :verify_authenticity_token

	def show
    render :show, :formats => [:html], :status => status_code
	end

	protected

	def status_code
		params[:status_code] || 500
	end
end

