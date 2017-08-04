class PagesController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:mturk_tokens]

  def index
  end

  def about
  end

  def test
  end

  def es_test
    client = Crowdbreaks::Client
    @resp = client.cluster.health
    render :test
  end

  def mturk_tokens
    puts "starting request"
    unless params[:token].present? and params[:key].present?
      head 400 # bad request
      return
    end

    # existence test for key pair
    record = MturkToken.find_by(token: params[:token], key: params[:key], used: false)
    if record.present?
      record.update_attributes!(used: true)
      head 200 # ok
    else
      head 403 # forbidden
    end
  end
end
