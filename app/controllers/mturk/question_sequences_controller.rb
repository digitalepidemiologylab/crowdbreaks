class Mturk::QuestionSequencesController < ApplicationController
  after_action :allow_cross_origin, only: [:show]

  def show
  end


  private

  def allow_cross_origin
    response.headers.delete "X-Frame-Options"
  end
end
