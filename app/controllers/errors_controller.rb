class ErrorsController < ApplicationController
  layout 'error'

	def show
    render :show, :status => status_code
	end

	protected

	def status_code
		params[:status_code] || 500
	end
end

